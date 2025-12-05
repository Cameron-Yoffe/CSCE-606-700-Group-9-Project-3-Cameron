require 'rails_helper'

RSpec.describe LetterboxdImportJob, type: :job do
  let(:user) { create(:user) }
  let(:csv_content) do
    <<~CSV
      Date,Name,Year,Letterboxd URI,Rating,Rewatch,Tags,Watched Date
      2024-01-15,Inception,2010,https://letterboxd.com/film/inception/,5,No,,2024-01-15
    CSV
  end

  describe '#perform' do
    before do
      client = instance_double(Tmdb::Client)
      allow(Tmdb::Client).to receive(:new).and_return(client)
      allow(client).to receive(:get).and_return({ 'results' => [] })
    end

    it 'imports diary using LetterboxdDiaryImporter' do
      importer = instance_double(LetterboxdDiaryImporter)
      allow(LetterboxdDiaryImporter).to receive(:new).and_return(importer)
      allow(importer).to receive(:import).and_return(
        LetterboxdImportBase::ImportResult.new(imported: 1, skipped: 0, errors: [])
      )

      described_class.perform_now(user.id, csv_content)

      expect(LetterboxdDiaryImporter).to have_received(:new).with(user)
      expect(importer).to have_received(:import)
    end

    it 'returns early when user not found' do
      expect(LetterboxdDiaryImporter).not_to receive(:new)

      described_class.perform_now(-1, csv_content)
    end

    it 'handles ImportError gracefully' do
      allow(LetterboxdDiaryImporter).to receive(:new).and_raise(
        LetterboxdImportBase::ImportError.new('Invalid file')
      )

      expect {
        described_class.perform_now(user.id, csv_content)
      }.not_to raise_error
    end
  end

  describe 'queue configuration' do
    it 'is enqueued in the default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end
  end
end
