require "rails_helper"

RSpec.describe UrlsController, type: :controller do
  let(:short_code) { "abc123" }
  let(:target_url) { "https://example.com" }
  let(:url) { instance_double(Url, short_code: short_code, target_url: target_url, is_active: true) }

  describe "GET #new" do
    it "returns a successful response" do
      get :new
      expect(response).to be_successful
    end

    it "assigns a new Url" do
      get :new
      expect(assigns(:url)).to be_a_new(Url)
    end

    it "initializes the session" do
      get :new
      expect(session[:initialized]).to be true
    end

    it "loads URLs for the session" do
      session_urls = [ url ]
      allow(SessionUrlsQuery).to receive_message_chain(:new, :call).and_return(session_urls)
      get :new
      expect(assigns(:urls)).to eq(session_urls)
    end
  end

  describe "POST #create" do
    let(:create_service) { instance_double(CreateUrlService, call!: url) }

    before do
      allow(CreateUrlService).to receive(:new).and_return(create_service)
      allow(SessionUrlsQuery).to receive_message_chain(:new, :call).and_return([])
    end

    context "when successful" do
      it "redirects to root path" do
        post :create, params: { url: { target_url: target_url } }
        expect(response).to redirect_to(root_path)
      end

      it "sets the short_code flash" do
        post :create, params: { url: { target_url: target_url } }
        expect(flash[:short_code]).to eq(short_code)
      end

      it "calls CreateUrlService with correct params" do
        expect(CreateUrlService).to receive(:new).with(
          an_instance_of(ActionController::Parameters).and(satisfy { |p| p["target_url"] == target_url }),
          hash_including(session_id: an_instance_of(String))
        ).and_return(create_service)
        post :create, params: { url: { target_url: target_url } }
      end
    end

    context "when ActiveRecord::RecordInvalid is raised" do
      let(:invalid_url) { Url.new }
      let(:record_invalid) { ActiveRecord::RecordInvalid.new(invalid_url) }

      before do
        allow(create_service).to receive(:call!).and_raise(record_invalid)
      end

      it "renders the new template" do
        post :create, params: { url: { target_url: target_url } }
        expect(response).to render_template(:new)
      end

      it "returns unprocessable entity status" do
        post :create, params: { url: { target_url: target_url } }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "assigns the invalid record to @url" do
        post :create, params: { url: { target_url: target_url } }
        expect(assigns(:url)).to eq(invalid_url)
      end
    end

    context "when an unexpected error is raised" do
      before do
        allow(create_service).to receive(:call!).and_raise(StandardError, "Something went wrong")
      end

      it "renders the new template" do
        post :create, params: { url: { target_url: target_url } }
        expect(response).to render_template(:new)
      end

      it "returns unprocessable entity status" do
        post :create, params: { url: { target_url: target_url } }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "adds a base error to @url" do
        post :create, params: { url: { target_url: target_url } }
        expect(assigns(:url).errors[:base]).to include("An unexpected error occurred. Please try again.")
      end
    end
  end

  describe "GET #show" do
    let(:visits) { [] }
    let(:next_page) { nil }
    let(:show_service) { instance_double(ShowUrlService, call: [ visits, next_page ]) }

    before do
      allow(Url).to receive(:find_by!).with(short_code: short_code).and_return(url)
      allow(ShowUrlService).to receive(:new).and_return(show_service)
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

    it "calls ShowUrlService with url and page params" do
      expect(ShowUrlService).to receive(:new).with(url: url, page: nil).and_return(show_service)
      get :show, params: { short_code: short_code }
    end

    context "when URL is not found" do
      before do
        allow(Url).to receive(:find_by!).and_raise(ActiveRecord::RecordNotFound)
      end

      it "returns a not found response" do
        get :show, params: { short_code: "nonexistent" }
        expect(response).to have_http_status(:not_found)
      end

      it "returns an error JSON body" do
        get :show, params: { short_code: "nonexistent" }
        expect(JSON.parse(response.body)).to eq("error" => "Url not found")
      end
    end
  end

  describe "PATCH #deactivate" do
    before do
      allow(Url).to receive(:find_by!).with(short_code: short_code).and_return(url)
    end

    context "when update succeeds" do
      before { allow(url).to receive(:update).with(is_active: false).and_return(true) }

      it "redirects to root path" do
        patch :deactivate, params: { short_code: short_code }
        expect(response).to redirect_to(root_path)
      end

      it "sets a notice flash" do
        patch :deactivate, params: { short_code: short_code }
        expect(flash[:notice]).to match(/#{short_code}/)
      end
    end

    context "when update fails" do
      before do
        allow(url).to receive(:update).with(is_active: false).and_return(false)
        allow(url).to receive_message_chain(:errors, :full_messages).and_return([ "some error" ])
      end

      it "redirects to root path" do
        patch :deactivate, params: { short_code: short_code }
        expect(response).to redirect_to(root_path)
      end

      it "sets an alert flash" do
        patch :deactivate, params: { short_code: short_code }
        expect(flash[:alert]).to match(/#{short_code}/)
      end
    end
  end

  describe "GET #redirect" do
    let(:create_visit_service) { instance_double(CreateVisitService, call!: true) }

    before do
      allow(Url).to receive(:find_by!).with(short_code: short_code).and_return(url)
      allow(CreateVisitService).to receive(:new).and_return(create_visit_service)
    end

    it "redirects to the target URL" do
      get :redirect, params: { short_code: short_code }
      expect(response).to redirect_to(target_url)
    end

    it "calls CreateVisitService" do
      expect(CreateVisitService).to receive(:new).with(url, anything).and_return(create_visit_service)
      get :redirect, params: { short_code: short_code }
    end

    context "when CreateVisitService raises an error" do
      before do
        allow(create_visit_service).to receive(:call!).and_raise(StandardError, "visit error")
      end

      it "still redirects to the target URL" do
        get :redirect, params: { short_code: short_code }
        expect(response).to redirect_to(target_url)
      end
    end

    context "when URL is not found" do
      before do
        allow(Url).to receive(:find_by!).and_raise(ActiveRecord::RecordNotFound)
      end

      it "returns not found" do
        get :redirect, params: { short_code: "nonexistent" }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
