class Url < ApplicationRecord
  has_many :visits, dependent: :destroy

  validate :limit_per_session, on: :create
  validates :target_url, presence: true
  validate  :target_url_must_be_valid_uri
  validates :short_code, uniqueness: true
  after_create :generate_short_code, :set_active

  def to_param
    short_code
  end

  private
  def target_url_must_be_valid_uri
    return if target_url.blank?

    unless uri?(target_url)
      errors.add(:target_url, "is not a valid URL")
    end
  end

  def uri?(string)
    uri = URI.parse(string)
    %w[ http https ].include?(uri.scheme)
  rescue URI::BadURIError, URI::InvalidURIError
    false
  end

  def generate_short_code
    return if short_code.present?
    short_code = ShortCodeGenerator.encode(id)
    update_column(:short_code, short_code)
  end

  def set_active
    update_column(:is_active, true)
  end

  def limit_per_session
    return unless session_id.present?

    existing_count = Url.lock.where(session_id: session_id, is_active: true).count

    if existing_count >= 5
      errors.add(:base, "Max number of URLs reached, please delete some and try again.")
    end
  end
end
