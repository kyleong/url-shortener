class LogVisitService
  def initialize(url, request)
    @url = url
    @request = request
  end

  def call!
    ip = @request.remote_ip

    visit = Visit.create!(
      url: @url,
      ip_address: ip,
      user_agent: @request.user_agent,
      referer: @request.referer,
      visited_at: Time.current
    )
    FetchGeolocationJob.perform_later(visit.id)
  rescue StandardError => e
    Rails.logger.warn "Failed to log visit: #{e.message}"
  end
end
