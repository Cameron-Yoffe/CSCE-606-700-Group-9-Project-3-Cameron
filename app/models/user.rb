class User < ApplicationRecord
  # Secure password
  has_secure_password validations: false

  # Associations
  has_many :diary_entries, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :watchlists, dependent: :destroy
  has_many :movies, through: :watchlists

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 20, message: "must be between 3 and 20 characters" }
  validates :password, presence: true, length: { minimum: 8, message: "must be at least 8 characters" }, if: :new_record?
  validates :password, confirmation: true, if: -> { password.present? }
  validates :password_confirmation, presence: true, if: -> { password.present? && new_record? }
  validates :first_name, length: { maximum: 50 }, allow_blank: true
  validates :last_name, length: { maximum: 50 }, allow_blank: true
  validates :bio, length: { maximum: 500 }, allow_blank: true

  # Custom password strength validation
  validate :password_strength, if: -> { password.present? && new_record? }

  private

  def password_strength
    return if password.blank?

    unless password.match?(/\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      errors.add(:password, "must include at least one uppercase letter, one lowercase letter, and one number")
    end
  end
end
