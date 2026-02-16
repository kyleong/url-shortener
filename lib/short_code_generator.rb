BASE62_CHARS = ("0".."9").to_a + ("a".."z").to_a + ("A".."Z").to_a
PREFIX_LENGTH = 7

class ShortCodeGenerator
  def self.generate(id, prefix_length: PREFIX_LENGTH)
    raise ArgumentError, "ID must be a positive integer" if id.nil? || id < 0

    prefix = generate_random_prefix(prefix_length)
    encoded_id = encode_base62(id)
    "#{prefix}#{encoded_id}"
  end

  def self.decode(short_code, prefix_length: PREFIX_LENGTH)
    return nil if short_code.nil? || short_code.length <= prefix_length

    encoded_id = short_code[prefix_length..]
    decode_base62(encoded_id)
  rescue
    nil
  end

  def self.valid?(short_code)
    return false if short_code.nil? || short_code.empty?

    short_code.chars.all? { |char| BASE62_CHARS.include?(char) }
  end

  private

  def self.generate_random_prefix(length)
    length.times.map { BASE62_CHARS.sample }.join
  end

  def self.encode_base62(num)
    return BASE62_CHARS[0] if num.zero?

    result = []
    while num > 0
      result << BASE62_CHARS[num % 62]
      num /= 62
    end

    result.reverse.join
  end

  def self.decode_base62(string)
    num = 0
    string.each_char do |char|
      num = num * 62 + BASE62_CHARS.index(char)
    end
    num
  end
end
