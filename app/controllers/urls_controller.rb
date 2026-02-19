class UrlsController < ApplicationController
  before_action :set_url, only: %i[ show ]
  def new
    session[:initialized] ||= true
    @url = Url.new
    @urls = Url.where(session_id: request.session.id.to_s).order(created_at: :desc)
  end

  def create
    @url = Url.new(url_params.merge(session_id: request.session.id))
    if @url.save
      redirect_to root_path, notice: "Your shortened URL is: #{(@url.short_code)}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @visit_count = @url.visits.count
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
    puts "Finding URL with short code: #{params[:short_code]}"
    @url = Url.find_by!(short_code: params[:short_code])
  end

  def url_params
    params.require(:url).permit(:target_url)
  end
end
