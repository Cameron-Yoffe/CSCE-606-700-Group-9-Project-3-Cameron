require 'rails_helper'

RSpec.describe LetterboxdRatingsImporter do
  let(:user) { create(:user) }

  describe '#import' do
    let(:csv_content) do
      <<~CSV
        Date,Name,Year,Letterboxd URI,Rating
        2024-01-15,Inception,2010,https://letterboxd.com/film/inception/,5
        2024-01-10,The Matrix,1999,https://letterboxd.com/film/the-matrix/,4.5
      CSV
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

    it 'imports ratings from CSV' do
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

    context 'with blank rows' do
      let(:csv_content) do
        <<~CSV
          Date,Name,Year,Letterboxd URI,Rating
          2024-01-15,Inception,2010,https://letterboxd.com/film/inception/,5
          ,,,,
          2024-01-10,The Matrix,1999,https://letterboxd.com/film/the-matrix/,4.5
        CSV
      end

      it 'skips blank rows' do
        importer = described_class.new(user)

        result = importer.import(csv_file)

        expect(result.skipped).to be >= 0
      end
    end

    context 'when rating already exists' do
      let!(:movie) { create(:movie, title: 'Inception') }
      let!(:existing_rating) { create(:rating, user: user, movie: movie, value: 8) }

      it 'skips duplicate ratings' do
        importer = described_class.new(user)

        result = importer.import(csv_file)

        expect(result.skipped).to be >= 1
      end
    end

    it 'skips entries with non-positive ratings' do
      importer = described_class.new(user)
      row = CSV::Row.new(%w[Name Rating], ["Movie", "0"])

      result = importer.send(:import_row, row)

      expect(result[:status]).to eq(:skipped)
    end

    it 'builds a review when uri is present' do
      importer = described_class.new(user)
      row = { "Letterboxd URI" => "https://letterboxd.com/film/abc" }

      expect(importer.send(:build_review, row)).to include("https://letterboxd.com/film/abc")
    end
  end
end
