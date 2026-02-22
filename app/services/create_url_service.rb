class CreateUrlService < ApplicationService
  def initialize(params, session_id:)
    @params = params
    @session_id = session_id
  end

  def call!
    url = Url.create!(@params.merge(session_id: @session_id))
    FetchUrlMetadataJob.perform_later(url.id)
    url
  end
end
