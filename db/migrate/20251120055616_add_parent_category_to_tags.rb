class AddParentCategoryToTags < ActiveRecord::Migration[8.1]
  def change
    add_column :tags, :parent_category, :string
    add_index :tags, :parent_category

    # Delete old tags to reseed with new hierarchy
    Tag.destroy_all

    # Define tag hierarchy: parent_category => specific_tags
    tag_hierarchy = {
      "comedy" => %w[ funny hilarious lighthearted slapstick witty ],
      "action" => %w[ explosive intense thrilling high-octane adventure ],
      "thriller" => %w[ suspenseful mysterious dark gripping intense ],
      "horror" => %w[ scary creepy terrifying unsettling disturbing ],
      "romantic" => %w[ heartwarming emotional touching romantic sweet ],
      "drama" => %w[ emotional powerful moving thought-provoking intense ],
      "sci-fi" => %w[ futuristic dystopian space exploration mind-bending visionary ],
      "fantasy" => %w[ magical mystical epic enchanting otherworldly ]
    }

    tag_hierarchy.each do |parent_category, specific_tags|
      # Create the parent/general tag
      Tag.find_or_create_by(name: parent_category) do |tag|
        tag.category = parent_category
        tag.parent_category = nil
      end

      # Create specific/subcategory tags
      specific_tags.each do |tag_name|
        Tag.find_or_create_by(name: tag_name) do |tag|
          tag.category = tag_name
          tag.parent_category = parent_category
        end
      end
    end
  end
end
