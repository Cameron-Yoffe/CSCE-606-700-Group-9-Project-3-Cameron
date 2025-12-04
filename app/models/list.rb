class List < ApplicationRecord
  belongs_to :user
  has_many :list_items, dependent: :destroy
  has_many :movies, through: :list_items

  validates :name, presence: true, length: { maximum: 100 }
end
