require "rails_helper"

RSpec.describe SessionUrlsQuery do
  let(:session_id) { "test-session-abc" }
  let(:other_session_id) { "other-session-xyz" }

  describe "#call" do
    context "filtering by session" do
      it "returns urls belonging to the given session" do
        url = create(:url, session_id: session_id, is_active: true)
        result = described_class.new(session_id).call
        expect(result).to include(url)
      end

      it "excludes urls from other sessions" do
        create(:url, session_id: other_session_id, is_active: true)
        result = described_class.new(session_id).call
        expect(result).to be_empty
      end
    end
  end
end
