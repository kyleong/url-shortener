require "rails_helper"

RSpec.describe Visit, type: :model do
  let(:url) { create(:url) }
  describe "associations" do
    it "belongs to a url" do
      visit = create(:visit, url: url)
      expect(visit.url).to eq(url)
    end
  end

  describe "callbacks" do
    describe "#broadcast_url" do
      it "broadcasts the new visit and updates the visit count" do
        expect_any_instance_of(Visit).to receive(:broadcast_prepend_to).with(
          url.id,
          target: "visits",
          partial: "urls/visit",
          locals: { visit: kind_of(Visit) }
        )

        expect_any_instance_of(Visit).to receive(:broadcast_update_to).with(
          url.id,
          target: "visit_count",
          html: "1 clicks"
        )

        create(:visit, url: url)
      end
    end

    describe "#broadcast_visit" do
      it "broadcasts the updated visit" do
        visit = create(:visit, url: url)
        target = ActionView::RecordIdentifier.dom_id(visit)

        expect(visit).to receive(:broadcast_replace_to).with(
          url.id,
          target: target,
          partial: "urls/visit",
          locals: { visit: visit }
        )

        visit.update(updated_at: Time.current)
      end
    end
  end
end
