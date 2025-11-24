class AddCategoryToTags < ActiveRecord::Migration[8.1]
  def change
    add_column :tags, :category, :string, default: "general"
    add_index :tags, :category

    # Seed predefined tags
    categories = {
      "comedy" => %w[ funny hilarious lighthearted slapstick witty ],
      "action" => %w[ explosive intense thrilling high-octane adventure ],
      "thriller" => %w[ suspenseful mysterious dark gripping intense ],
      "horror" => %w[ scary creepy terrifying unsettling disturbing ],
      "romantic" => %w[ heartwarming emotional touching romantic sweet ]
    }

    categories.each do |category, tags|
      tags.each do |tag_name|
        Tag.find_or_create_by(name: tag_name) do |tag|
          tag.category = category
        end
      end
    end
  end
end
