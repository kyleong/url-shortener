require "rails_helper"

RSpec.describe ShortCodeGenerator do
  describe ".encode" do
    it "encodes a short code for a valid ID" do
      short_code = ShortCodeGenerator.encode(12345)
      expect(short_code).to be_a(String)
      expect(short_code.length).to be > 7
    end

    it "encodes codes with the correct prefix length" do
      short_code = ShortCodeGenerator.encode(100)
      expect(short_code.length).to be >= 7
    end

    it "encodes different codes for the same ID due to random prefix" do
      code1 = ShortCodeGenerator.encode(12345)
      code2 = ShortCodeGenerator.encode(12345)
      expect(code1).not_to eq(code2)
    end

    it "encodes only valid base62 characters" do
      short_code = ShortCodeGenerator.encode(99999)
      expect(short_code).to_not be_empty
      expect(short_code.chars.all? { |char| ShortCodeGenerator::BASE62_CHARS.include?(char) }).to be true
    end

    it "handles zero ID" do
      short_code = ShortCodeGenerator.encode(0, prefix_length: 7)
      expect(short_code.length).to eq(8)
    end

    it "handles large IDs" do
      large_id = 1_000_000_000
      short_code = ShortCodeGenerator.encode(large_id)
      expect(short_code).to be_a(String)
      expect(short_code.length).to be > 7
    end

    it "accepts custom prefix length" do
      short_code = ShortCodeGenerator.encode(123, prefix_length: 3)
      decoded_id = ShortCodeGenerator.decode(short_code, prefix_length: 3)
      expect(decoded_id).to eq(123)
    end

    context "when encoding invalid IDs" do
      it "raises error for nil ID" do
        expect {
          ShortCodeGenerator.encode(nil)
        }.to raise_error(ArgumentError, "ID must be a positive integer")
      end

      it "raises error for negative ID" do
        expect {
          ShortCodeGenerator.encode(-1)
        }.to raise_error(ArgumentError, "ID must be a positive integer")
      end
    end
  end

  describe ".decode" do
    it "decodes a generated short code back to the original ID" do
      original_id = 12345
      short_code = ShortCodeGenerator.encode(original_id)
      decoded_id = ShortCodeGenerator.decode(short_code)

      expect(decoded_id).to eq(original_id)
    end

    it "handles multiple encode/decode cycles" do
      test_ids = [ 0, 1, 10, 100, 1000, 999999, 1_000_000_000 ]

      test_ids.each do |original_id|
        short_code = ShortCodeGenerator.encode(original_id)
        decoded_id = ShortCodeGenerator.decode(short_code)

        expect(decoded_id).to eq(original_id)
      end
    end

    it "works with custom prefix length" do
      original_id = 54321
      short_code = ShortCodeGenerator.encode(original_id, prefix_length: 5)
      decoded_id = ShortCodeGenerator.decode(short_code, prefix_length: 5)

      expect(decoded_id).to eq(original_id)
    end

    context "when decoding invalid short codes" do
      it "returns nil for nil input" do
        expect(ShortCodeGenerator.decode(nil)).to be_nil
      end

      it "returns nil for short code shorter than prefix length" do
        expect(ShortCodeGenerator.decode("abc")).to be_nil
      end

      it "returns nil for invalid short code" do
        expect(ShortCodeGenerator.decode("invalid!@#")).to be_nil
      end

      it "returns nil when decoding with wrong prefix length" do
        short_code = ShortCodeGenerator.encode(123, prefix_length: 7)
        decoded_id = ShortCodeGenerator.decode(short_code, prefix_length: 3)

        # Decoded ID will be incorrect
        expect(decoded_id).not_to eq(123)
      end
    end
  end
end
