class LetterboxdRatingsImportJob < ApplicationJob
  queue_as :default

  def perform(user_id, file_content)
    user = User.find_by(id: user_id)
    return unless user

    importer = LetterboxdRatingsImporter.new(user)
    importer.import(StringIO.new(file_content))
  rescue LetterboxdRatingsImporter::ImportError => e
    Rails.logger&.warn("Letterboxd ratings import failed for user #{user_id}: #{e.message}")
  end
end
