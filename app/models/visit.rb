class Visit < ApplicationRecord
  belongs_to :url

  after_create_commit :broadcast_url
  after_update_commit :broadcast_visit

  private

  def broadcast_url
    return unless url.present?

    broadcast_prepend_to url.id,
      target: "visits",
      partial: "urls/visit",
      locals: { visit: self }

    broadcast_update_to url.id,
      target: "visit_count",
      html: "#{url.visits.count} clicks"
  end

  def broadcast_visit
    return unless url.present?
    broadcast_replace_to url.id,
      target: ActionView::RecordIdentifier.dom_id(self),
      partial: "urls/visit",
      locals: { visit: self }
  end
end
