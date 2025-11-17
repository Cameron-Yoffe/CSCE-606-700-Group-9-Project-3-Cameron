class User < ApplicationRecord
  # Associations
  has_many :diary_entries, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :watchlists, dependent: :destroy
  has_many :movies, through: :watchlists

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 20 }
  validates :password_digest, presence: true
  validates :first_name, length: { maximum: 50 }, allow_blank: true
  validates :last_name, length: { maximum: 50 }, allow_blank: true
  validates :bio, length: { maximum: 500 }, allow_blank: true
end
