class FetchGeolocationJob < ApplicationJob
  queue_as :default

  def perform(visit_id)
    visit = Visit.find(visit_id)
    ip = visit.ip_address
    location = Geocoder.search(ip).first

    visit.update(
      country: location&.country,
      city: location&.city,
      country_code: location&.country_code,
      latitude: location&.latitude,
      longitude: location&.longitude
    )
  rescue StandardError => e
    Rails.logger.warn "Failed to fetch geolocation for IP #{visit.ip_address}: #{e.message}"
  end
end
