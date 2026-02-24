require "rails_helper"

RSpec.describe UrlsHelper, type: :helper do
  let(:request_double) { instance_double(ActionDispatch::Request, host_with_port: "example.com:3000") }

  before do
    allow(helper).to receive(:request).and_return(request_double)
  end

  describe "#short_url" do
    it "builds a short url from a short code string" do
      expect(helper.short_url("abc123")).to eq("example.com:3000/abc123")
    end

    it "builds a short url from a Url object" do
      url = Url.allocate
      allow(url).to receive(:short_code).and_return("xyz789")

      expect(helper.short_url(url)).to eq("example.com:3000/xyz789")
    end

    it "raises when given an unsupported type" do
      expect { helper.short_url(123) }.to raise_error(ArgumentError, "Expected a String or Url object, got Integer")
    end

    context "when with_protocol: true" do
      it "uses http in development" do
        allow(Rails.env).to receive(:development?).and_return(true)

        expect(helper.short_url("abc123", with_protocol: true)).to eq("http://example.com:3000/abc123")
      end

      it "uses https outside development" do
        allow(Rails.env).to receive(:development?).and_return(false)

        expect(helper.short_url("abc123", with_protocol: true)).to eq("https://example.com:3000/abc123")
      end
    end
  end
end
