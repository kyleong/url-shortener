class FetchGeolocationJob < ApplicationJob
  queue_as :default

  def perform(visit_id)
    Rails.logger.info("Starting FetchGeolocationJob for visit_id: #{visit_id}")
    visit = Visit.find(visit_id)
    ip = visit.ip_address
    Rails.logger.info("Fetching geolocation for IP: #{ip}")

    location = Geocoder.search(ip).first

    visit.update(
      country: location&.country,
      city: location&.city,
      country_code: location&.country_code,
      latitude: location&.latitude,
      longitude: location&.longitude
    )
    Rails.logger.info("Successfully updated geolocation for visit_id: #{visit_id}")
  rescue StandardError => e
    Rails.logger.warn("Failed to fetch geolocation for IP #{visit&.ip_address}: #{e.message}")
  end
end
