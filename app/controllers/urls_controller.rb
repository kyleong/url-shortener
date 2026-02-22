class UrlsController < ApplicationController
  before_action :set_url, only: %i[ show deactivate ]

  def new
    session[:initialized] ||= true
    @url = Url.new
    load_urls
  end

  def create
    session_id = request.session.id.to_s

    @url = CreateUrlService.new(url_params, session_id: session_id).call!

    redirect_to root_path, short_code: @url.short_code
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
      redirect_to root_path, notice: "URL #{@url.short_code} deleted!"
    else
    Rails.logger.debug @url.errors.full_messages
      redirect_to root_path, alert: "Update failed"
    end
  end

  def redirect
    @url = Url.find_by(short_code: params[:short_code])
    LogVisitService.new(@url, request).call!

    if @url.nil? || !@url.is_active
      render plain: "URL not found", status: :not_found
    else
      redirect_to @url.target_url, allow_other_host: true
    end
  end

  private
  def render_new_with_errors(url, message = nil)
    @url = url
    @url.errors.add(:base, message) if message
    load_urls
    render :new, status: :unprocessable_entity
  end

  def set_url
    @url = Url.find_by!(short_code: params[:short_code])
  end

  def url_params
    params.require(:url).permit(:target_url)
  end

  def load_urls
    @urls = Url.where(session_id: request.session.id.to_s, is_active: true).order(created_at: :desc)
  end
end
