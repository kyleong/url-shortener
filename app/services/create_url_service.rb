class CreateUrlService < ApplicationService
  def initialize(params, session_id, host)
    @params = params
    @session_id = session_id
    @host = host
  end

  def call!
    url = Url.create!(@params.merge(session_id: @session_id, current_host: @host))
    FetchUrlMetadataJob.perform_later(url.id)
    url
  end
end
