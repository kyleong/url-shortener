require "rails_helper"

RSpec.describe CreateUrlService do
  let(:params) { { target_url: "https://example.com" } }
  let(:session_id) { "abc123" }

  before do
    allow(FetchUrlMetadataJob).to receive(:perform_later)
  end

  describe "#call!" do
    subject(:service_call) { described_class.new(params, session_id: session_id).call! }

    it "creates a new Url with the given params and session_id" do
      expect { service_call }.to change(Url, :count).by(1)
      url = Url.last
      expect(url.target_url).to eq("https://example.com")
      expect(url.session_id).to eq("abc123")
      expect(FetchUrlMetadataJob).to have_received(:perform_later).with(url.id)
    end

    context "when save! fails" do
      let(:url_instance) { instance_double(Url) }
      let(:error) { ActiveRecord::RecordInvalid.new(Url.new) }

      before do
        allow(url_instance).to receive(:save!).and_raise(error)
        allow(Url).to receive(:new).and_return(url_instance)
      end

      it "raises an error" do
        expect(Url).to receive(:new).with(params.merge(session_id: session_id)).and_return(url_instance)
        expect(url_instance)
          .to receive(:save!)
          .and_raise(error)
        expect {
          service_call
        }.to raise_error(ActiveRecord::RecordInvalid)
        expect(FetchUrlMetadataJob).not_to have_received(:perform_later)
        expect(Url.count).to eq(0)
      end
    end

    context "when Url.new raises an unexpected error" do
      let(:error) { StandardError.new("Unexpected error") }

      before do
        allow(Url).to receive(:new).and_raise(error)
      end

      it "raises an error" do
        expect(Url).to receive(:new).and_raise(error)
        expect_any_instance_of(Url).not_to receive(:save!)
        expect {
          service_call
        }.to raise_error(StandardError)
        expect(FetchUrlMetadataJob).not_to have_received(:perform_later)
        expect(Url.count).to eq(0)
      end
    end
  end
end
