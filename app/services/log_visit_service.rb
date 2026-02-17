class LogVisitService
  def initialize(url, request)
    @url = url
    @request = request
  end

  def call!
    ip = @request.remote_ip
    location = Geocoder.search(ip).first

    Visit.create!(
      url: @url,
      ip_address: ip,
      country: location&.country,
      city: location&.city,
      country_code: location&.country_code,
      latitude: location&.latitude,
      longitude: location&.longitude,
      user_agent: @request.user_agent,
      referer: @request.referer,
      visited_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.warn "Failed to log visit: #{e.message}"
  end
end
