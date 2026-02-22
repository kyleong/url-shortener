class CreateUrlService < ApplicationService
  def initialize(params, session_id:)
    @params = params
    @session_id = session_id
  end

  def call!
    url = Url.new(@params.merge(session_id: @session_id))
    url.save!
    FetchUrlMetadataJob.perform_later(url.id)
    url
  end
end
