require "rails_helper"

RSpec.describe "Rate limiting", type: :request do
  let(:short_code) { "abc123" }
  let(:target_url) { "https://example.com" }
  let(:url) { create(:url, short_code: short_code, target_url: target_url) }

  describe "POST /urls rate limit" do
    before do
      allow(CreateUrlService).to receive(:call!).and_return(url)
      allow(SessionUrlsQuery).to receive_message_chain(:new, :call).and_return([])
    end

    context "when IP exceeds 60 requests per hour" do
      it "returns 429 after limit is exceeded" do
        61.times do
          post "/urls",
            params: { url: { target_url: target_url } },
            headers: { "REMOTE_ADDR" => "1.2.3.4" }
        end

        expect(response).to have_http_status(:too_many_requests)
      end

      it "does not throttle a different IP" do
        60.times do
          post "/urls",
            params: { url: { target_url: target_url } },
            headers: { "REMOTE_ADDR" => "1.2.3.4" }
        end

        post "/urls",
          params: { url: { target_url: target_url } },
          headers: { "REMOTE_ADDR" => "5.6.7.8" }

        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end

  describe "GET /:short_code (redirect) rate limit" do
    before do
      url
      allow(CreateVisitService).to receive(:call!).and_return(true)
    end

    context "when IP exceeds 60 requests per minute" do
      it "returns 429 after limit is exceeded" do
        60.times { get "/#{short_code}", headers: { "REMOTE_ADDR" => "2.3.4.5" } }
        get "/#{short_code}", headers: { "REMOTE_ADDR" => "2.3.4.5" }

        expect(response).to have_http_status(:too_many_requests)
      end

      it "does not throttle a different IP" do
        60.times { get "/#{short_code}", headers: { "REMOTE_ADDR" => "2.3.4.5" } }
        get "/#{short_code}", headers: { "REMOTE_ADDR" => "3.4.5.6" }

        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end

  describe "GET /urls/:short_code (show) rate limit" do
    before do
      url # ensure record exists
      allow(ShowUrlService).to receive(:call).and_return([ [], nil ])
    end

    context "when IP exceeds 60 requests per minute" do
      it "returns 429 after limit is exceeded" do
        60.times { get "/urls/#{short_code}", headers: { "REMOTE_ADDR" => "3.4.5.6" } }
        get "/urls/#{short_code}", headers: { "REMOTE_ADDR" => "3.4.5.6" }

        expect(response).to have_http_status(:too_many_requests)
      end

      it "does not throttle a different IP" do
        60.times { get "/urls/#{short_code}", headers: { "REMOTE_ADDR" => "3.4.5.6" } }
        get "/urls/#{short_code}", headers: { "REMOTE_ADDR" => "7.8.9.0" }

        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end

  describe "throttled response format" do
    before do
      allow(CreateUrlService).to receive(:call!).and_return(url)
      allow(SessionUrlsQuery).to receive_message_chain(:new, :call).and_return([])
    end

    it "returns a JSON error body" do
      61.times do
        post "/urls",
          params: { url: { target_url: target_url } },
          headers: { "REMOTE_ADDR" => "4.5.6.7" }
      end

      expect(response).to have_http_status(:too_many_requests)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Too many requests. Please try again later.")
    end

    it "includes a Retry-After header in development" do
      allow(Rails.env).to receive(:development?).and_return(true)

      61.times do
        post "/urls",
          params: { url: { target_url: target_url } },
          headers: { "REMOTE_ADDR" => "4.5.6.8" }
      end

      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers["Retry-After"]).to be_present
    end
  end
end
