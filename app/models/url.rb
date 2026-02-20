class Url < ApplicationRecord
  has_many :visits, dependent: :destroy

  validate :limit_per_session, on: :create
  validates :target_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid HTTP or HTTPS URL" }
  validates :short_code, uniqueness: true
  after_create :generate_short_code, :set_active

  def to_param
    short_code
  end

  private
  def generate_short_code
    return if short_code.present?
    short_code = ShortCodeGenerator.new(id).call
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
