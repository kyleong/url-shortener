class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :set_permissions_policy

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def set_permissions_policy
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=(), payment=(), usb=(), interest-cohort=()"
  end
end
