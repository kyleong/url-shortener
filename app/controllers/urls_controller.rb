class UrlsController < ApplicationController
  before_action :set_url, only: %i[ show deactivate redirect ]
  before_action :load_urls, only: %i[new create]

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found_response

  def new
    Rails.logger.info("Rendering new URL form")
    session[:initialized] ||= true
    @url = Url.new
  end

  def create
    Rails.logger.info("Creating a new URL with params: " + url_params.to_h.inspect)
    session_id = request.session.id.to_s
    @url = CreateUrlService.call!(url_params, session_id, request.host)
    Rails.logger.info("Successfully created URL with short_code: #{@url.short_code}")
    Rails.cache.delete("session:#{session_id}:urls")
    flash[:short_code] = @url.short_code
    redirect_to root_path, notice: "URL with #{@url.short_code} created!"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Validation failed: #{e.record.errors.full_messages.join(", ")}")
    render_new_with_errors(e.record)
  rescue => e
    Rails.logger.error("Unexpected error in UrlsController#create: #{e.message}")
    render_new_with_errors(Url.new, "An unexpected error occurred. Please try again.")
  end

  def show
    Rails.logger.info("Showing URL details for short_code: #{@url.short_code}")
    @visits, @next_page = ShowUrlService.call(@url, params[:page])
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def deactivate
    Rails.logger.info("Deactivating URL with short_code: #{@url.short_code}")
    if @url.update(is_active: false)
      Rails.logger.info("Successfully deactivated URL with short_code: #{@url.short_code}")
      Rails.cache.delete("url:#{@url.short_code}")
      Rails.cache.delete("session:#{@url.session_id}:urls")
      redirect_to root_path, notice: "URL with #{@url.short_code} deleted!"
    else
      Rails.logger.error(@url.errors.full_messages)
      redirect_to root_path, alert: "Failed to delete URL with #{@url.short_code}. Please try again."
    end
  end

  def redirect
    Rails.logger.info("Redirecting to target URL for short_code: #{@url.short_code}")
    CreateVisitService.call!(@url, request)
  rescue => e
    Rails.logger.warn("Error creating visit for URL #{@url.short_code}: #{e.message}")
  ensure
    redirect_to @url.target_url, allow_other_host: true
  end

  private
  def render_new_with_errors(url, message = nil)
    @url = url
    @url.errors.add(:base, message) if message
    render :new, status: :unprocessable_content
  end

  def set_url
    short_code = params[:short_code]
    Rails.logger.info("Fetching URL with short_code: #{short_code}")
    @url = Rails.cache.fetch("url:#{short_code}", expires_in: 1.hour) do
      Url.find_by!(short_code: short_code, is_active: true)
    end
  end

  def url_params
    params.require(:url).permit(:target_url)
  end

  def load_urls
    session_id = request.session.id.to_s
    @urls = Rails.cache.fetch("session:#{session_id}:urls", expires_in: 5.minutes) do
      SessionUrlsQuery.new(session_id).call
    end
  end

  def render_not_found_response(exception)
    render json: { error: "Url not found" }, status: :not_found
  end
end
