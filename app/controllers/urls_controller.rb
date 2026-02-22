class UrlsController < ApplicationController
  before_action :set_url, only: %i[ show deactivate redirect ]
  before_action :load_urls, only: %i[new create]

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found_response

  def new
    session[:initialized] ||= true
    @url = Url.new
  end

  def create
    session_id = request.session.id.to_s
    @url = CreateUrlService.new(url_params, session_id: session_id).call!
    flash[:short_code] = @url.short_code
    redirect_to root_path
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Validation failed: #{e.record.errors.full_messages.join(", ")}")
    render_new_with_errors(e.record)
  rescue => e
    Rails.logger.error("Unexpected error in UrlsController#create: #{e.message}")
    render_new_with_errors(Url.new, "An unexpected error occurred. Please try again.")
  end

  def show
    @visits, @next_page = ShowUrlService.new(url: @url, page: params[:page]).call
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def deactivate
    if @url.update(is_active: false)
      redirect_to root_path, notice: "URL with #{@url.short_code} deleted!"
    else
      Rails.logger.error @url.errors.full_messages
      redirect_to root_path, alert: "Failed to delete URL with #{@url.short_code}. Please try again."
    end
  end

  def redirect
    CreateVisitService.new(@url, request).call!
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
    @url = Url.find_by!(short_code: params[:short_code])
  end

  def url_params
    params.require(:url).permit(:target_url)
  end

  def load_urls
    @urls = SessionUrlsQuery.new(request.session.id.to_s).call
  end

  def render_not_found_response(exception)
    render json: { error: "Url not found" }, status: :not_found
  end
end
