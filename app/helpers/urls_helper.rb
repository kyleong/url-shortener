module UrlsHelper
  def short_url(url_or_short_code, with_protocol: false)
    if !url_or_short_code.is_a?(String) && !url_or_short_code.is_a?(Url)
      raise ArgumentError, "Expected a String or Url object, got #{url_or_short_code.class.name}"
    end

    code = url_or_short_code.try(:short_code) || url_or_short_code
    url = "#{request.host_with_port}/#{code}"
    with_protocol ? "#{Rails.env.development? ? "http" : "https"}://#{url}" : url
  end
end
