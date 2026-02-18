class Visit < ApplicationRecord
  belongs_to :url

  after_create_commit :broadcast_visit

  private

  def broadcast_visit
    return unless url.present?

    broadcast_prepend_to url.id,
      target: "visits",
      partial: "urls/visit",
      locals: { visit: self }
  end
end
