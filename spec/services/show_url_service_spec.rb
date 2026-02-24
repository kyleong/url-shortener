require "rails_helper"

RSpec.describe ShowUrlService do
  describe "#call" do
    let(:url) { create(:url) }

    it "returns nil next page when there are fewer visits than the page size" do
      create_list(:visit, 3, url: url)
      visits, next_page = described_class.call(url, 1)
      expect(visits.count).to eq(3)
      expect(next_page).to eq(nil)
    end

    context "when visits is more than the page size" do
      it "paginates visits and returns next page when more results exist" do
        create_list(:visit, 7, url: url)
        visits, next_page = described_class.call(url, 1)
        expect(visits.count).to eq(5)
        expect(next_page).to eq(2)
      end

      it "returns nil next page when on the last page" do
        create_list(:visit, 7, url: url)
        visits, next_page = described_class.call(url, 2)
        expect(visits.count).to eq(2)
        expect(next_page).to eq(nil)
      end
    end
  end
end
