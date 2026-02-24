require "rails_helper"

RSpec.describe FetchUrlMetadataJob, type: :job do
  describe "#perform" do
    let(:url) { create(:url) }

    it "updates the url with fetched metadata" do
      allow_any_instance_of(FetchUrlMetadataJob).to receive(:fetch_url_metadata)
        .with(url.target_url)
        .and_return(status_code: 200, title: "Example Title")

      described_class.perform_now(url.id)

      url.reload
      expect(url.fetch_status_code).to eq(200)
      expect(url.title).to eq("Example Title")
      expect(url.fetched_at).to be_present
    end

    context "when fetch_url_metadata returns nil or raises an error" do
      let (:url) { create(:url, :unfetched) }
      it "does not update when metadata is nil" do
        allow_any_instance_of(FetchUrlMetadataJob).to receive(:fetch_url_metadata)
          .with(url.target_url)
          .and_return(nil)

        described_class.perform_now(url.id)

        url.reload
        expect(url.fetch_status_code).to be_nil
        expect(url.title).to be_nil
        expect(url.fetched_at).to be_nil
      end

      it "does not update when an error occurs" do
        allow_any_instance_of(FetchUrlMetadataJob).to receive(:fetch_url_metadata)
          .with(url.target_url)
          .and_raise(StandardError.new("Network error"))

        expect { described_class.perform_now(url.id) }.not_to raise_error

        url.reload
        expect(url.fetch_status_code).to be_nil
        expect(url.title).to be_nil
        expect(url.fetched_at).to be_nil
      end
    end
  end

  describe "#fetch_url_metadata" do
    let(:job) { described_class.new }

    it "returns status code and title for a successful response" do
      http_double = double(get: instance_double(Net::HTTPOK, code: "200", body: "<title>Example</title>"))
      allow(Net::HTTP).to receive(:start).and_yield(http_double)

      result = job.send(:fetch_url_metadata, "https://example.com")
      expect(result).to eq(status_code: 200, title: "Example")
    end

    it "follows redirects" do
      redirect_response = instance_double(Net::HTTPRedirection, code: "301", body: nil)
      ok_response = instance_double(Net::HTTPOK, code: "200", body: "<title>Redirected</title>")

      allow(redirect_response).to receive(:is_a?).with(Net::HTTPRedirection).and_return(true)
      allow(redirect_response).to receive(:[]).with("location").and_return("https://example.org")
      allow(ok_response).to receive(:is_a?).with(Net::HTTPRedirection).and_return(false)

      http_double = double
      allow(http_double).to receive(:get)
        .and_return(redirect_response, ok_response)

      allow(Net::HTTP).to receive(:start).and_yield(http_double)

      result = job.send(:fetch_url_metadata, "https://example.com")
      expect(result).to eq(status_code: 200, title: "Redirected")
    end


    context "when an error occurs during HTTP request" do
      it "returns nil and logs a warning" do
        allow(Net::HTTP).to receive(:start).and_raise(StandardError.new("Network error"))
        expect(Rails.logger).to receive(:warn).with(/Error while fetching metadata for URL/)

        result = job.send(:fetch_url_metadata, "https://example.com")
        expect(result).to be_nil
      end
    end
  end
end
