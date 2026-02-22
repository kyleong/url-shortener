require "rails_helper"

RSpec.describe CreateUrlService do
  let(:params) { { target_url: "https://example.com" } }
  let(:session_id) { "abc123" }

  before do
    allow(FetchUrlMetadataJob).to receive(:perform_later)
  end

  describe "#call!" do
    subject(:service_call) { described_class.new(params, session_id: session_id).call! }

    it "successfully creates a new Url" do
      expect { service_call }.to change(Url, :count).by(1)
      url = Url.last
      expect(url.target_url).to eq("https://example.com")
      expect(url.session_id).to eq("abc123")
      expect(FetchUrlMetadataJob).to have_received(:perform_later).with(url.id)
    end

    context "when save! fails" do
      let(:error) { ActiveRecord::RecordInvalid.new(Url.new) }

      before do
        allow(Url).to receive(:create!).and_raise(error)
      end

      it "raises an error" do
        expect {
          described_class.new(params, session_id: session_id).call!
        }.to raise_error(error)
        expect(FetchUrlMetadataJob).not_to have_received(:perform_later)
        expect(Url.count).to eq(0)
      end
    end
  end
end
