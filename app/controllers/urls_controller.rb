class UrlsController < ApplicationController
  before_action :set_url, only: %i[ show deactivate ]

  def new
    session[:initialized] ||= true
    @url = Url.new
    load_urls
  end

  def create
    @url = Url.new(url_params.merge(session_id: request.session.id))
    if @url.save
      flash[:short_code] = @url.short_code
      FetchUrlMetadataJob.perform_later(@url.id)
      redirect_to root_path, notice: "Your shortened URL is: #{(@url.short_code)}"
    else
      load_urls
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @page = params[:page].to_i
    @page = 1 if @page <= 0

    per_page = 5
    offset = (@page - 1) * per_page

    @visits = @url.visits.order(created_at: :desc)
                .limit(per_page)
                .offset(offset)

    @next_page = @page + 1 if @url.visits.count > @page * per_page

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
