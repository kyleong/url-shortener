class SessionUrlsQuery
  def initialize(session_id, relation = Url.all)
    @session_id = session_id
    @relation = relation
  end

  def call
    @relation
      .where(session_id: @session_id, is_active: true)
      .order(created_at: :desc)
  end
end
