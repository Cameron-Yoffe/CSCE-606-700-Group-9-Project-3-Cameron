class LetterboxdImportJob < ApplicationJob
  queue_as :default

  def perform(user_id, file_content)
    user = User.find_by(id: user_id)
    return unless user

    importer = LetterboxdDiaryImporter.new(user)
    importer.import(StringIO.new(file_content))
  rescue LetterboxdDiaryImporter::ImportError => e
    Rails.logger&.warn("Letterboxd import failed for user #{user_id}: #{e.message}")
  end
end
