class UrlsController < ApplicationController
  before_action :set_url, only: %i[ show ]
  def new
    @url = Url.new
  end

  def create
    @url = Url.new(url_params.merge(is_active: true))
    if @url.save
      redirect_to url_path(@url.short_code), notice: "Your shortened URL is: #{(@url.short_code)}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def redirect
    @url = Url.find_by!(short_code: params[:short_code])
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
