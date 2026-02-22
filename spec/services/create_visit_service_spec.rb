require "rails_helper"

RSpec.describe CreateVisitService do
  let(:url) { create(:url) }
  let(:request) do
    instance_double(
      "ActionDispatch::Request",
      remote_ip: "1.2.3.4",
      user_agent: "RSpec UA",
      referer: "https://example.com"
    )
  end

  before do
    allow(FetchGeolocationJob).to receive(:perform_later)
  end

  describe "#call!" do
    it "successfully creates a new Visit" do
      expect {
        described_class.new(url, request).call!
      }.to change(Visit, :count).by(1)
      visit = Visit.last

      expect(visit.url).to eq(url)
      expect(visit.ip_address).to eq("1.2.3.4")
      expect(visit.user_agent).to eq("RSpec UA")
      expect(visit.referer).to eq("https://example.com")
      expect(FetchGeolocationJob).to have_received(:perform_later).with(visit.id)
    end

    context "when Visit creation fails" do
      let(:error) { ActiveRecord::RecordInvalid.new(Visit.new) }

      before do
        allow(Visit).to receive(:create!).and_raise(error)
      end

      it "raises an error" do
        expect {
          described_class.new(url, request).call!
        }.to raise_error(error)
        expect(FetchGeolocationJob).not_to have_received(:perform_later)
        expect(Visit.count).to eq(0)
      end
    end
  end
end
