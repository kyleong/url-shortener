require "rails_helper"

RSpec.describe Url, type: :model do
  describe "validations" do
    it "is valid with a valid target_url" do
      url = Url.new(target_url: "http://example.com")
      expect(url).to be_valid
    end

    it "is invalid without a target_url" do
      url = Url.new(target_url: nil)
      expect(url).not_to be_valid
      expect(url.errors[:target_url]).to include("can't be blank")
    end

    it "is invalid with an improperly formatted target_url" do
      url = Url.new(target_url: "invalid-url")
      expect(url).not_to be_valid
    end

    it "is invalid with a non-unique short_code" do
      existing_url = Url.create!(target_url: "http://example.com")
      new_url = Url.new(target_url: "http://example2.com", short_code: existing_url.short_code)
      expect(new_url).not_to be_valid
      expect(new_url.errors[:short_code]).to include("has already been taken")
    end
  end

  describe "#generate_short_code" do
    it "generates a unique short code" do
      url = Url.new(target_url: "http://example.com")
      url.save
      expect(url.short_code).not_to be_nil
      expect(url.short_code.length).to be >= 7
    end

    it "generates unique short codes for different URLs" do
      url1 = Url.create(target_url: "http://example.com")
      url2 = Url.create(target_url: "http://example2.com")
      expect(url1.short_code).not_to eq(url2.short_code)
    end
  end
end
