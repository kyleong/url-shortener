class ShortCodeGenerator
  BASE62_CHARS = ("0".."9").to_a +
                 ("a".."z").to_a +
                 ("A".."Z").to_a

  PREFIX_LENGTH = 7

  def self.encode(id, prefix_length: PREFIX_LENGTH)
    raise ArgumentError, "ID must be a positive integer" if id.nil? || id < 0

    prefix = generate_random_prefix(prefix_length)
    encoded_id = encode_base62(id)
    "#{prefix}#{encoded_id}"
  end

  def self.decode(short_code, prefix_length: PREFIX_LENGTH)
    return nil if short_code.nil? || short_code.length <= prefix_length

    encoded_id = short_code[prefix_length..]
    decode_base62(encoded_id)
  rescue StandardError
    nil
  end

  private_class_method

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
    string.each_char.reduce(0) do |num, char|
      index = BASE62_CHARS.index(char)
      raise ArgumentError, "Invalid character" if index.nil?
      num * 62 + index
    end
  end
end
