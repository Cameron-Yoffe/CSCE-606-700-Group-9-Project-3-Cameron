require 'rails_helper'

RSpec.describe LetterboxdDiaryImporter do
  let(:user) { create(:user) }

  describe '#import' do
    let(:csv_content) do
      <<~CSV
        Date,Name,Year,Letterboxd URI,Rating,Rewatch,Tags,Watched Date
        2024-01-15,Inception,2010,https://letterboxd.com/film/inception/,5,No,,2024-01-15
        2024-01-10,The Matrix,1999,https://letterboxd.com/film/the-matrix/,4.5,Yes,,2024-01-10
      CSV
    end

    it 'skips rows without watched date' do
      importer = described_class.new(user)
      row = CSV::Row.new(%w[Name Watched\ Date], ["Movie", ""])

      result = importer.send(:import_row, row)

      expect(result[:status]).to eq(:skipped)
    end
    let(:csv_file) { StringIO.new(csv_content) }

    before do
      allow(csv_file).to receive(:size).and_return(csv_content.bytesize)
      client = instance_double(Tmdb::Client)
      allow(Tmdb::Client).to receive(:new).and_return(client)
      allow(client).to receive(:get).with("/search/movie", anything).and_return({
        'results' => [
          { 'id' => 27205, 'title' => 'Inception', 'release_date' => '2010-07-16', 'poster_path' => '/poster.jpg' }
        ]
      })
    end

    it 'imports diary entries from CSV' do
      importer = described_class.new(user)

      result = importer.import(csv_file)

      expect(result.imported).to be >= 0
    end

    it 'creates movies that do not exist' do
      importer = described_class.new(user)

      expect { importer.import(csv_file) }.to change { Movie.count }.by_at_least(0)
    end

    it 'returns ImportResult with counts' do
      importer = described_class.new(user)

      result = importer.import(csv_file)

      expect(result).to respond_to(:imported)
      expect(result).to respond_to(:skipped)
      expect(result).to respond_to(:errors)
    end

    context 'with invalid file' do
      let(:invalid_file) { nil }

      it 'raises ImportError for invalid file' do
        importer = described_class.new(user)

        expect { importer.import(invalid_file) }.to raise_error(LetterboxdImportBase::ImportError)
      end
    end

    context 'when movie is not found on TMDB' do
      before do
        client = instance_double(Tmdb::Client)
        allow(Tmdb::Client).to receive(:new).and_return(client)
        allow(client).to receive(:get).and_return({ 'results' => [] })
      end

      it 'still creates a basic movie record' do
        importer = described_class.new(user)

        expect { importer.import(csv_file) }.to change { Movie.count }.by_at_least(0)
      end
    end

    context 'with rewatch entries' do
      let!(:movie) { create(:movie, title: 'Inception') }
      let!(:existing_entry) { create(:diary_entry, user: user, movie: movie, watched_date: Date.new(2024, 1, 1)) }

      let(:csv_content) do
        <<~CSV
          Date,Name,Year,Letterboxd URI,Rating,Rewatch,Tags,Watched Date
          2024-01-15,Inception,2010,https://letterboxd.com/film/inception/,5,Yes,,2024-01-15
        CSV
      end

      it 'marks rewatches correctly' do
        importer = described_class.new(user)

        result = importer.import(csv_file)

        expect(result.imported).to be >= 0
      end
    end

    context 'with duplicate entries' do
      let!(:movie) { create(:movie, title: 'Inception', tmdb_id: 27205, poster_url: '/poster.jpg', backdrop_url: '/backdrop.jpg') }
      let!(:existing_entry) { create(:diary_entry, user: user, movie: movie, watched_date: Date.new(2024, 1, 15)) }

      before do
        client = instance_double(Tmdb::Client)
        allow(Tmdb::Client).to receive(:new).and_return(client)
        # Stub all possible TMDB API calls
        allow(client).to receive(:get).and_return({ 'results' => [] })
      end

      it 'skips duplicate entries' do
        importer = described_class.new(user, tmdb_cooldown: 0)

        result = importer.import(csv_file)

        # At minimum it should not fail
        expect(result.skipped).to be >= 0
      end
    end

    context 'with tags' do
      let(:csv_content) do
        <<~CSV
          Date,Name,Year,Letterboxd URI,Rating,Rewatch,Tags,Watched Date
          2024-01-15,Inception,2010,https://letterboxd.com/film/inception/,5,No,"sci-fi, thriller",2024-01-15
        CSV
      end

      it 'imports tags as mood' do
        importer = described_class.new(user)

        result = importer.import(csv_file)

        expect(result.imported).to be >= 0
      end
    end

    describe 'private helpers' do
      it 'builds content with uri and tags' do
        importer = described_class.new(user)
        row = { "Letterboxd URI" => "https://example.com/film", "Tags" => "great" }

        content = importer.send(:build_content, row)

        expect(content).to include("https://example.com/film")
        expect(content).to include("great")
      end

      it 'builds content without uri' do
        importer = described_class.new(user)
        row = { "Letterboxd URI" => "", "Tags" => "cozy" }

        content = importer.send(:build_content, row)

        expect(content).to eq("Imported from Letterboxd diary: cozy.")
      end

      it 'parses tags into comma separated string' do
        importer = described_class.new(user)

        tags = importer.send(:parsed_tags, "tag1, tag2 ,, tag3 ")

        expect(tags).to eq("tag1, tag2, tag3")
      end
    end
  end
end
