class Url < ApplicationRecord
  has_many :visits, dependent: :destroy

  validates :target_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid HTTP or HTTPS URL" }
  validates :short_code, uniqueness: true
  after_create :generate_short_code

  def to_param
    short_code
  end

  private
  def generate_short_code
    return if short_code.present?
    short_code = ShortCodeGenerator.new(id).call
    update_column(:short_code, short_code)
  end
end
