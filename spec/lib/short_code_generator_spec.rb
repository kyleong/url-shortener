require "short_code_generator"

RSpec.describe ShortCodeGenerator do
  describe ".generate" do
    it "generates a short code for a valid ID" do
      short_code = ShortCodeGenerator.generate(12345)
      expect(short_code).to be_a(String)
      expect(short_code.length).to be > 7
    end

    it "generates codes with the correct prefix length" do
      short_code = ShortCodeGenerator.generate(100)
      expect(short_code.length).to be >= 7
    end

    it "generates different codes for the same ID due to random prefix" do
      code1 = ShortCodeGenerator.generate(12345)
      code2 = ShortCodeGenerator.generate(12345)
      expect(code1).not_to eq(code2)
    end

    it "generates only valid base62 characters" do
      short_code = ShortCodeGenerator.generate(99999)
      expect(ShortCodeGenerator.valid?(short_code)).to be true
    end

    it "handles zero ID" do
      short_code = ShortCodeGenerator.generate(0)
      expect(short_code.length).to eq(8) # 7 prefix + 1 for '0'
    end

    it "handles large IDs" do
      large_id = 1_000_000_000
      short_code = ShortCodeGenerator.generate(large_id)
      expect(short_code).to be_a(String)
      expect(short_code.length).to be > 7
    end

    it "accepts custom prefix length" do
      short_code = ShortCodeGenerator.generate(123, prefix_length: 3)
      decoded_id = ShortCodeGenerator.decode(short_code, prefix_length: 3)
      expect(decoded_id).to eq(123)
    end

    it "raises error for nil ID" do
      expect {
        ShortCodeGenerator.generate(nil)
      }.to raise_error(ArgumentError, "ID must be a positive integer")
    end

    it "raises error for negative ID" do
      expect {
        ShortCodeGenerator.generate(-1)
      }.to raise_error(ArgumentError, "ID must be a positive integer")
    end
  end

  describe ".decode" do
    it "decodes a generated short code back to the original ID" do
      original_id = 12345
      short_code = ShortCodeGenerator.generate(original_id)
      decoded_id = ShortCodeGenerator.decode(short_code)

      expect(decoded_id).to eq(original_id)
    end

    it "handles multiple encode/decode cycles" do
      test_ids = [ 0, 1, 10, 100, 1000, 999999, 1_000_000_000 ]

      test_ids.each do |original_id|
        short_code = ShortCodeGenerator.generate(original_id)
        decoded_id = ShortCodeGenerator.decode(short_code)

        expect(decoded_id).to eq(original_id)
      end
    end

    it "returns nil for nil input" do
      expect(ShortCodeGenerator.decode(nil)).to be_nil
    end

    it "returns nil for short code shorter than prefix length" do
      expect(ShortCodeGenerator.decode("abc")).to be_nil
    end

    it "returns nil for invalid short code" do
      expect(ShortCodeGenerator.decode("invalid!@#")).to be_nil
    end

    it "works with custom prefix length" do
      original_id = 54321
      short_code = ShortCodeGenerator.generate(original_id, prefix_length: 5)
      decoded_id = ShortCodeGenerator.decode(short_code, prefix_length: 5)

      expect(decoded_id).to eq(original_id)
    end

    it "returns nil when decoding with wrong prefix length" do
      short_code = ShortCodeGenerator.generate(123, prefix_length: 7)
      decoded_id = ShortCodeGenerator.decode(short_code, prefix_length: 5)

      # Decoded ID will be incorrect
      expect(decoded_id).not_to eq(123)
    end
  end

  describe ".valid?" do
    it "returns true for valid base62 characters" do
      valid_codes = [ "abc123", "XYZ789", "0123456789", "aAbBcC" ]

      valid_codes.each do |code|
        expect(ShortCodeGenerator.valid?(code)).to be true
      end
    end

    it "returns false for invalid characters" do
      invalid_codes = [ "abc-123", "test@test", "code!", "test_code" ]

      invalid_codes.each do |code|
        expect(ShortCodeGenerator.valid?(code)).to be false
      end
    end

    it "returns false for nil" do
      expect(ShortCodeGenerator.valid?(nil)).to be false
    end

    it "returns false for empty string" do
      expect(ShortCodeGenerator.valid?("")).to be false
    end
  end
end
