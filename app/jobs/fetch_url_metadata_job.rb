class FetchUrlMetadataJob < ApplicationJob
  queue_as :default

  def perform(url_id)
    url = Url.find(url_id)
    metadata = fetch_url_metadata(url.target_url)
    if metadata
      url.update(
        fetch_status_code: metadata[:status_code],
        title: metadata[:title],
        fetched_at: Time.current
      )
    end
  end

  private

  def fetch_url_metadata(url_string, limit = 5)
    return nil if limit == 0

    uri = URI.parse(url_string)
    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: 5,
      read_timeout: 5
    ) do |http|
      http.get(uri.request_uri)
    end

    if response.is_a?(Net::HTTPRedirection)
      return fetch_url_metadata(response["location"], limit - 1)
    end

    status_code = response.code.to_i
    body = response.body.encode("UTF-8", "binary", invalid: :replace, undef: :replace, replace: "")
    title = body[/<title[^>]*>(.*?)<\/title>/im, 1]&.strip
    {
      status_code: status_code,
      title: title
    }
  rescue => e
    Rails.logger.warn("Could not fetch metadata for #{url_string}: #{e.message}")
    nil
  end
end
