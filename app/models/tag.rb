class Tag < ApplicationRecord
  # Associations
  has_many :movie_tags, dependent: :destroy
  has_many :movies, through: :movie_tags

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :name, length: { minimum: 1, maximum: 50 }
  validates :category, presence: true

  # Normalize name to lowercase for case-insensitive storage
  before_save :downcase_name

  # Scopes
  scope :by_name, ->(name) { where("LOWER(name) = ?", name.downcase) }
  scope :by_category, ->(category) { where(category: category) }
  scope :main_categories, -> { where(parent_category: nil) }
  scope :subcategories_for, ->(parent) { where(parent_category: parent) }

  MAIN_CATEGORIES = %w[ comedy action thriller horror romantic drama sci-fi fantasy ].freeze

  private

  def downcase_name
    self.name = name.downcase if name.present?
  end
end
