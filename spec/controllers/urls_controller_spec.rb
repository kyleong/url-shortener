require "rails_helper"

RSpec.describe UrlsController, type: :controller do
  let(:short_code) { "abc123" }
  let(:target_url) { "https://example.com" }
  let(:url) { create(:url, short_code: short_code, target_url: target_url) }
  let(:session_id) { "test-session-id" }

  before do
    allow(request.session).to receive(:id).and_return(session_id)
    allow(Rails.cache).to receive(:fetch).and_call_original
    allow(Rails.cache).to receive(:delete)
  end

  describe "GET #new" do
    before { get :new }

    it "returns a successful response" do
      expect(response).to be_successful
    end

    it "assigns a new Url" do
      expect(assigns(:url)).to be_a_new(Url)
    end

    it "sets session[:initialized]" do
      expect(session[:initialized]).to be true
    end

    it "is idempotent when session is already initialized" do
      session[:initialized] = true
      get :new
      expect(session[:initialized]).to be true
    end

    context "when session URLs are cached" do
      let(:cached_urls) { [ url ] }

      before do
        allow(Rails.cache).to receive(:fetch)
          .with("session:#{session_id}:urls", anything)
          .and_return(cached_urls)
        get :new
      end

      it "assigns the cached URLs" do
        expect(assigns(:urls)).to eq(cached_urls)
      end
    end

    context "when session URLs are not cached" do
      before do
        Rails.cache.clear
        allow(Rails.cache).to receive(:fetch).and_call_original
        allow(SessionUrlsQuery).to receive_message_chain(:new, :call).and_return([ url ])
        get :new
      end

      it "falls back to SessionUrlsQuery" do
        expect(assigns(:urls)).to eq([ url ])
      end
    end
  end

  describe "POST #create" do
    subject(:post_create) { post :create, params: { url: { target_url: target_url } } }

    before do
      allow(SessionUrlsQuery).to receive_message_chain(:new, :call).and_return([])
    end

    context "when creation succeeds" do
      before { allow(CreateUrlService).to receive(:call!).and_return(url) }

      it "redirects to root path" do
        post_create
        expect(response).to redirect_to(root_path)
      end

      it "sets the short_code flash" do
        post_create
        expect(flash[:short_code]).to eq(short_code)
      end

      it "invalidates the session URL cache" do
        expect(Rails.cache).to receive(:delete).with("session:#{session_id}:urls")
        post_create
      end

      it "passes the session ID to CreateUrlService" do
        expect(CreateUrlService).to receive(:call!).with(anything, session_id, anything).and_return(url)
        post_create
      end
    end

    context "when ActiveRecord::RecordInvalid is raised" do
      let(:invalid_url) { Url.new }

      before do
        allow(CreateUrlService).to receive(:call!)
          .and_raise(ActiveRecord::RecordInvalid.new(invalid_url))
      end

      it "renders the new template with unprocessable_content status" do
        post_create
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "assigns the invalid record to @url" do
        post_create
        expect(assigns(:url)).to eq(invalid_url)
      end
    end

    context "when an unexpected error is raised" do
      before do
        allow(CreateUrlService).to receive(:call!).and_raise(StandardError, "boom")
      end

      it "renders the new template with unprocessable_content status" do
        post_create
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "adds a base error to @url" do
        post_create
        expect(assigns(:url).errors[:base]).to include("An unexpected error occurred. Please try again.")
      end
    end
  end

  describe "GET #show" do
    let(:visits) { [] }
    let(:next_page) { nil }

    before do
      allow(Rails.cache).to receive(:fetch).with("url:#{short_code}", anything).and_return(url)
      allow(ShowUrlService).to receive(:call).and_return([ visits, next_page ])
    end

    it "returns a successful response" do
      get :show, params: { short_code: short_code }
      expect(response).to be_successful
    end

    it "assigns @visits and @next_page" do
      get :show, params: { short_code: short_code }
      expect(assigns(:visits)).to eq(visits)
      expect(assigns(:next_page)).to eq(next_page)
    end

    it "passes the page param to ShowUrlService" do
      expect(ShowUrlService).to receive(:call).with(url, "2").and_return([ visits, next_page ])
      get :show, params: { short_code: short_code, page: "2" }
    end

    it "passes nil page param when not provided" do
      expect(ShowUrlService).to receive(:call).with(url, nil).and_return([ visits, next_page ])
      get :show, params: { short_code: short_code }
    end

    context "when the URL is not in the cache" do
      before do
        Rails.cache.clear
        allow(Rails.cache).to receive(:fetch).and_call_original
      end

      it "fetches from the database and returns successfully" do
        url # ensure record exists
        get :show, params: { short_code: short_code }
        expect(response).to be_successful
      end
    end

    context "when the URL does not exist" do
      before do
        allow(Rails.cache).to receive(:fetch).and_raise(ActiveRecord::RecordNotFound)
      end

      it "returns a not_found response with an error body" do
        get :show, params: { short_code: "nonexistent" }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq("error" => "Url not found")
      end
    end
  end

  describe "PATCH #deactivate" do
    before do
      allow(Rails.cache).to receive(:fetch).with("url:#{short_code}", anything).and_return(url)
    end

    context "when deactivation succeeds" do
      before { allow(url).to receive(:update).with(is_active: false).and_return(true) }

      it "redirects to root path with a notice" do
        patch :deactivate, params: { short_code: short_code }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include(short_code)
      end

      it "invalidates the URL and session caches" do
        expect(Rails.cache).to receive(:delete).with("url:#{short_code}")
        expect(Rails.cache).to receive(:delete).with("session:#{url.session_id}:urls")
        patch :deactivate, params: { short_code: short_code }
      end
    end

    context "when deactivation fails" do
      before do
        allow(url).to receive(:update).with(is_active: false).and_return(false)
        allow(url).to receive_message_chain(:errors, :full_messages).and_return([ "some error" ])
      end

      it "redirects to root path with an alert" do
        patch :deactivate, params: { short_code: short_code }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include(short_code)
      end

      it "does not invalidate any caches" do
        expect(Rails.cache).not_to receive(:delete).with("url:#{short_code}")
        patch :deactivate, params: { short_code: short_code }
      end
    end
  end

  describe "GET #redirect" do
    before do
      allow(Rails.cache).to receive(:fetch).with("url:#{short_code}", anything).and_return(url)
      allow(CreateVisitService).to receive(:call!).and_return(true)
    end

    it "redirects to the target URL" do
      get :redirect, params: { short_code: short_code }
      expect(response).to redirect_to(target_url)
    end

    it "records the visit with the request object" do
      expect(CreateVisitService).to receive(:call!).with(url, kind_of(ActionDispatch::Request))
      get :redirect, params: { short_code: short_code }
    end

    context "when CreateVisitService raises an error" do
      before { allow(CreateVisitService).to receive(:call!).and_raise(StandardError, "visit error") }

      it "still redirects to the target URL" do
        get :redirect, params: { short_code: short_code }
        expect(response).to redirect_to(target_url)
      end
    end

    context "when the URL does not exist" do
      before { allow(Rails.cache).to receive(:fetch).and_raise(ActiveRecord::RecordNotFound) }

      it "returns not_found" do
        get :redirect, params: { short_code: "nonexistent" }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
