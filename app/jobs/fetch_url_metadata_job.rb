class FetchUrlMetadataJob < ApplicationJob
  queue_as :default

  def perform(url_id)
    Rails.logger.info("Starting FetchUrlMetadataJob for url_id: #{url_id}")
    url = Url.find(url_id)
    Rails.logger.info("Fetching metadata for URL: #{url.target_url}")

    metadata = fetch_url_metadata(url.target_url)
    if metadata
      url.update(
        fetch_status_code: metadata[:status_code],
        title: metadata[:title],
        fetched_at: Time.current
      )
      Rails.logger.info("Successfully updated metadata for URL: #{url.target_url}")
    else
      Rails.logger.warn("No metadata found for URL: #{url.target_url}")
    end
  rescue StandardError => e
    Rails.logger.warn("Failed to fetch metadata for URL #{url&.target_url}: #{e.message}")
  end

  private

  def fetch_url_metadata(url_string, limit = 5)
    Rails.logger.info("Fetching metadata for URL: #{url_string} with redirect limit: #{limit}")
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
      Rails.logger.info("Redirected to: #{response["location"]}")
      return fetch_url_metadata(response["location"], limit - 1)
    end

    status_code = response.code.to_i
    body = response.body.encode("UTF-8", "binary", invalid: :replace, undef: :replace, replace: "")
    title = body[/<title[^>]*>(.*?)<\/title>/im, 1]&.strip
    Rails.logger.info("Fetched metadata: status_code=#{status_code}, title=#{title}")
    {
      status_code: status_code,
      title: title
    }
  rescue StandardError => e
    Rails.logger.warn("Error while fetching metadata for URL #{url_string}: #{e.message}")
    nil
  end
end
