class AddContainsSpoilersToRatings < ActiveRecord::Migration[8.1]
  def change
    add_column :ratings, :contains_spoilers, :boolean, default: false, null: false
  end
end
