require "rails_helper"

RSpec.describe Url, type: :model do
  describe "validations" do
    it "is valid with a valid target_url" do
      url = Url.new(target_url: "http://example.com")
      expect(url).to be_valid
    end

    it "is still valid as long as the session has 5 or fewer active URLs" do
      session_id = "test-session1"
      5.times { create(:url, session_id: session_id, is_active: true) }
      Url.last.update(is_active: false)

      url = Url.new(target_url: "http://example.com/extra", session_id: session_id)
      expect(url).to be_valid
    end

    context "invalid target_url" do
      it "is invalid without a target_url" do
        url = Url.new(target_url: nil)
        expect(url).not_to be_valid
        expect(url.errors[:target_url]).to include("can't be blank")
      end

      it "is invalid with an improperly formatted target_url" do
        url = Url.new(target_url: "http://exa{mple.com")
        expect(url).not_to be_valid
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

      it "is invalid when target_url is same as current_host" do
        expect { Url.create!(target_url: "http://myapp.com", current_host: "myapp.com") }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "maximum URLs per session" do
      it "is invalid when session has more than 5 active URLs" do
        session_id = "test-session"
        5.times { create(:url, session_id: session_id, is_active: true) }
        url = Url.new(target_url: "http://example.com/extra", session_id: session_id)
        expect(url).not_to be_valid
      end
    end
  end

  describe "#to_param" do
    it "returns the short_code" do
      url = Url.new(target_url: "http://example.com")
      url.short_code = "abc123"
      expect(url.to_param).to eq("abc123")
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
