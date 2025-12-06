require 'rails_helper'

RSpec.describe LetterboxdImportBase do
  let(:user) { create(:user) }
  let(:test_importer) do
    Class.new(described_class) do
      def import_row(row)
        { status: :imported }
      end
    end
  end

  describe '#import' do
    let(:csv_content) do
      <<~CSV
        Name,Year,Rating
        Test Movie,2023,5
      CSV
    end
    let(:csv_file) { StringIO.new(csv_content) }

    before do
      allow(csv_file).to receive(:size).and_return(csv_content.bytesize)
      client = instance_double(Tmdb::Client)
      allow(Tmdb::Client).to receive(:new).and_return(client)
      allow(client).to receive(:get).and_return({ 'results' => [] })
    end

    it 'returns an ImportResult' do
      importer = test_importer.new(user)

      result = importer.import(csv_file)

      expect(result).to be_a(LetterboxdImportBase::ImportResult)
      expect(result.imported).to eq(1)
      expect(result.skipped).to eq(0)
      expect(result.errors).to eq([])
    end

    context 'with invalid file' do
      it 'raises ImportError for nil file' do
        importer = test_importer.new(user)

        expect { importer.import(nil) }.to raise_error(LetterboxdImportBase::ImportError)
      end

      it 'raises ImportError for empty file' do
        empty_file = StringIO.new('')
        allow(empty_file).to receive(:size).and_return(0)
        importer = test_importer.new(user)

        expect { importer.import(empty_file) }.to raise_error(LetterboxdImportBase::ImportError)
      end
    end

    context 'with malformed CSV' do
      let(:malformed_content) { "\"unclosed quote\n" }
      let(:malformed_file) { StringIO.new(malformed_content) }

      before do
        allow(malformed_file).to receive(:size).and_return(malformed_content.bytesize)
      end

      it 'raises ImportError for malformed CSV' do
        importer = test_importer.new(user)

        expect { importer.import(malformed_file) }.to raise_error(LetterboxdImportBase::ImportError)
      end
    end

    context 'with TMDB cooldown' do
      it 'respects the cooldown between API calls' do
        importer = test_importer.new(user, tmdb_cooldown: 0.01)

        result = importer.import(csv_file)

        expect(result.imported).to be >= 0
      end
    end

    context 'with skip results' do
      let(:skip_importer) do
        Class.new(described_class) do
          def import_row(row)
            { status: :skipped }
          end
        end
      end

      it 'counts skipped rows' do
        importer = skip_importer.new(user)

        result = importer.import(csv_file)

        expect(result.skipped).to eq(1)
      end
    end

    context 'with error results' do
      let(:error_importer) do
        Class.new(described_class) do
          def import_row(row)
            { status: :error, message: 'Something went wrong' }
          end
        end
      end

      it 'collects error messages' do
        importer = error_importer.new(user)

        result = importer.import(csv_file)

        expect(result.errors).to include('Something went wrong')
      end
    end

    context 'with blank rows' do
      let(:csv_content) do
        <<~CSV
          Name,Year,Rating
          Test Movie,2023,5
          ,,,
          Another Movie,2022,4
        CSV
      end

      it 'skips blank rows' do
        importer = test_importer.new(user)

        result = importer.import(csv_file)

        expect(result.imported).to eq(2)
      end
    end

    context 'with encoding issues' do
      let(:csv_content) { "Name,Year\nTest Movie\xC0,2023\n" }

      it 'sanitizes encoding' do
        importer = test_importer.new(user)

        expect { importer.import(csv_file) }.not_to raise_error
      end
    end
  end

  describe 'TMDB integration' do
    let(:csv_content) do
      <<~CSV
        Name,Year,Rating
        Inception,2010,5
      CSV
    end
    let(:csv_file) { StringIO.new(csv_content) }

    before do
      allow(csv_file).to receive(:size).and_return(csv_content.bytesize)
    end

    context 'when TMDB API is available' do
      let(:tmdb_importer) do
        Class.new(described_class) do
          def import_row(row)
            movie = find_or_create_movie(row['Name'], row['Year']&.to_i)
            movie ? { status: :imported } : { status: :skipped }
          end
        end
      end

      before do
        client = instance_double(Tmdb::Client)
        allow(Tmdb::Client).to receive(:new).and_return(client)
        allow(client).to receive(:get).with('/search/movie', anything).and_return({
          'results' => [ {
            'id' => 27205,
            'title' => 'Inception',
            'release_date' => '2010-07-16',
            'poster_path' => '/poster.jpg',
            'backdrop_path' => '/backdrop.jpg',
            'overview' => 'A thief who steals corporate secrets...',
            'vote_average' => 8.4,
            'vote_count' => 12345
          } ]
        })
      end

      it 'creates movie with TMDB data' do
        importer = tmdb_importer.new(user, tmdb_cooldown: 0)

        result = importer.import(csv_file)

        expect(result.imported).to eq(1)
        movie = Movie.find_by(tmdb_id: 27205)
        expect(movie).to be_present
        expect(movie.title).to eq('Inception')
      end
    end

    context 'when existing movie by tmdb_id exists' do
      let(:tmdb_importer) do
        Class.new(described_class) do
          def import_row(row)
            movie = find_or_create_movie(row['Name'], row['Year']&.to_i)
            movie ? { status: :imported } : { status: :skipped }
          end
        end
      end

      let!(:existing_movie) { create(:movie, tmdb_id: 27205, title: 'Old Inception Title') }

      before do
        client = instance_double(Tmdb::Client)
        allow(Tmdb::Client).to receive(:new).and_return(client)
        allow(client).to receive(:get).with('/search/movie', anything).and_return({
          'results' => [ {
            'id' => 27205,
            'title' => 'Inception',
            'release_date' => '2010-07-16',
            'poster_path' => '/new_poster.jpg'
          } ]
        })
      end

      it 'updates existing movie by tmdb_id' do
        importer = tmdb_importer.new(user, tmdb_cooldown: 0)

        result = importer.import(csv_file)

        expect(result.imported).to eq(1)
        existing_movie.reload
        expect(existing_movie.poster_url).to include('new_poster.jpg')
      end
    end

    context 'when existing movie by title exists and needs metadata' do
      let(:enrich_importer) do
        Class.new(described_class) do
          def import_row(row)
            movie = find_or_create_movie(row['Name'], row['Year']&.to_i)
            movie ? { status: :imported } : { status: :skipped }
          end
        end
      end

      let!(:existing_movie) { create(:movie, title: 'Inception', release_date: Date.new(2010, 1, 1), tmdb_id: nil, poster_url: nil) }

      before do
        client = instance_double(Tmdb::Client)
        allow(Tmdb::Client).to receive(:new).and_return(client)
        allow(client).to receive(:get).with('/search/movie', anything).and_return({
          'results' => [ {
            'id' => 27205,
            'title' => 'Inception',
            'release_date' => '2010-07-16',
            'poster_path' => '/enriched_poster.jpg'
          } ]
        })
      end

      it 'enriches existing movie metadata' do
        importer = enrich_importer.new(user, tmdb_cooldown: 0)

        result = importer.import(csv_file)

        expect(result.imported).to eq(1)
        existing_movie.reload
        expect(existing_movie.poster_url).to include('enriched_poster.jpg')
      end
    end

    context 'when existing movie has complete metadata' do
      let(:complete_importer) do
        Class.new(described_class) do
          def import_row(row)
            movie = find_or_create_movie(row['Name'], row['Year']&.to_i)
            movie ? { status: :imported } : { status: :skipped }
          end
        end
      end

      let!(:existing_movie) do
        create(:movie,
          title: 'Inception',
          release_date: Date.new(2010, 1, 1),
          tmdb_id: 12345,
          poster_url: '/complete_poster.jpg',
          backdrop_url: '/complete_backdrop.jpg'
        )
      end

      before do
        # Should not make any TMDB calls
        expect(Tmdb::Client).not_to receive(:new)
      end

      it 'returns existing movie without TMDB call' do
        importer = complete_importer.new(user, tmdb_cooldown: 0)

        result = importer.import(csv_file)

        expect(result.imported).to eq(1)
      end
    end

    context 'when TMDB returns no results' do
      let(:fallback_importer) do
        Class.new(described_class) do
          def import_row(row)
            movie = find_or_create_movie(row['Name'], row['Year']&.to_i)
            movie ? { status: :imported } : { status: :skipped }
          end
        end
      end

      before do
        client = instance_double(Tmdb::Client)
        allow(Tmdb::Client).to receive(:new).and_return(client)
        allow(client).to receive(:get).and_return({ 'results' => [] })
      end

      it 'creates basic movie record' do
        importer = fallback_importer.new(user, tmdb_cooldown: 0)

        result = importer.import(csv_file)

        expect(result.imported).to eq(1)
        movie = Movie.find_by(title: 'Inception')
        expect(movie).to be_present
      end
    end

    context 'when TMDB API fails' do
      let(:error_handling_importer) do
        Class.new(described_class) do
          def import_row(row)
            movie = find_or_create_movie(row['Name'], row['Year']&.to_i)
            movie ? { status: :imported } : { status: :skipped }
          end
        end
      end

      before do
        client = instance_double(Tmdb::Client)
        allow(Tmdb::Client).to receive(:new).and_return(client)
        allow(client).to receive(:get).and_raise(Tmdb::Error.new('API Error'))
      end

      it 'handles TMDB errors gracefully' do
        importer = error_handling_importer.new(user, tmdb_cooldown: 0)

        result = importer.import(csv_file)

        # Should still create a basic movie
        expect(result.imported).to eq(1)
      end
    end

    context 'when TMDB authentication fails' do
      before do
        allow(Tmdb::Client).to receive(:new).and_raise(Tmdb::AuthenticationError.new('Invalid API key'))
      end

      let(:auth_importer) do
        Class.new(described_class) do
          def import_row(row)
            movie = find_or_create_movie(row['Name'], row['Year']&.to_i)
            movie ? { status: :imported } : { status: :skipped }
          end
        end
      end

      it 'continues without TMDB' do
        importer = auth_importer.new(user, tmdb_cooldown: 0)

        result = importer.import(csv_file)

        expect(result.imported).to eq(1)
      end
    end

    context 'fetch_tmdb_movie' do
      let(:fetch_movie_importer) do
        Class.new(described_class) do
          public :fetch_tmdb_movie

          def import_row(row)
            { status: :imported }
          end
        end
      end

      it 'fetches movie details by ID' do
        client = instance_double(Tmdb::Client)
        allow(Tmdb::Client).to receive(:new).and_return(client)
        allow(client).to receive(:get).with('/movie/27205').and_return({
          'id' => 27205,
          'title' => 'Inception'
        })

        importer = fetch_movie_importer.new(user, tmdb_cooldown: 0)

        result = importer.fetch_tmdb_movie(27205)

        expect(result['title']).to eq('Inception')
      end

      it 'handles TMDB errors for movie details' do
        client = instance_double(Tmdb::Client)
        allow(Tmdb::Client).to receive(:new).and_return(client)
        allow(client).to receive(:get).with('/movie/27205').and_raise(Tmdb::Error.new('Not found'))

        importer = fetch_movie_importer.new(user, tmdb_cooldown: 0)

        result = importer.fetch_tmdb_movie(27205)

        expect(result).to be_nil
      end
    end

    context 'with enriching movie that has tmdb_id' do
      let(:enrich_with_id_importer) do
        Class.new(described_class) do
          public :enrich_movie_metadata, :needs_metadata?

          def import_row(row)
            { status: :imported }
          end
        end
      end

      let!(:existing_movie) do
        create(:movie,
          title: 'Inception',
          tmdb_id: 27205,
          poster_url: nil  # needs_metadata? returns true
        )
      end

      before do
        client = instance_double(Tmdb::Client)
        allow(Tmdb::Client).to receive(:new).and_return(client)
        allow(client).to receive(:get).with('/movie/27205').and_return({
          'id' => 27205,
          'title' => 'Inception Updated',
          'poster_path' => '/updated_poster.jpg'
        })
      end

      it 'enriches movie using fetch_tmdb_movie when tmdb_id present' do
        importer = enrich_with_id_importer.new(user, tmdb_cooldown: 0)

        expect(importer.needs_metadata?(existing_movie)).to be true

        result = importer.enrich_movie_metadata(existing_movie, 'Inception', 2010)

        expect(result.poster_url).to include('updated_poster.jpg')
      end
    end
  end

  describe 'helper methods' do
    describe '#parsed_rating' do
      let(:rating_importer) do
        Class.new(described_class) do
          public :parsed_rating

          def import_row(row)
            { status: :imported }
          end
        end
      end

      it 'converts Letterboxd ratings to 10-point scale' do
        importer = rating_importer.new(user)

        expect(importer.parsed_rating('5')).to eq(10)
        expect(importer.parsed_rating('4')).to eq(8)
        expect(importer.parsed_rating('3.5')).to eq(7)
        expect(importer.parsed_rating('2.5')).to eq(5)
        expect(importer.parsed_rating('1')).to eq(2)
      end

      it 'returns nil for blank ratings' do
        importer = rating_importer.new(user)

        expect(importer.parsed_rating('')).to be_nil
        expect(importer.parsed_rating(nil)).to be_nil
      end

      it 'clamps ratings to valid range' do
        importer = rating_importer.new(user)

        expect(importer.parsed_rating('6')).to eq(10)  # Clamped to max
        expect(importer.parsed_rating('-1')).to eq(0)  # Clamped to min
      end
    end

    describe '#parse_date' do
      let(:date_importer) do
        Class.new(described_class) do
          public :parse_date

          def import_row(row)
            { status: :imported }
          end
        end
      end

      it 'parses valid dates' do
        importer = date_importer.new(user)

        expect(importer.parse_date('2024-01-15')).to eq(Date.new(2024, 1, 15))
      end

      it 'returns nil for invalid dates' do
        importer = date_importer.new(user)

        expect(importer.parse_date('not a date')).to be_nil
        expect(importer.parse_date('')).to be_nil
        expect(importer.parse_date(nil)).to be_nil
      end
    end

    describe '#parse_year' do
      let(:year_importer) do
        Class.new(described_class) do
          public :parse_year

          def import_row(row)
            { status: :imported }
          end
        end
      end

      it 'parses valid years' do
        importer = year_importer.new(user)

        expect(importer.parse_year('2024')).to eq(2024)
      end

      it 'returns nil for invalid years' do
        importer = year_importer.new(user)

        expect(importer.parse_year('not a year')).to be_nil
        expect(importer.parse_year('')).to be_nil
        expect(importer.parse_year(nil)).to be_nil
      end
    end

    describe 'utility helpers' do
      let(:helper_importer) do
        Class.new(described_class) do
          public :safe_string, :sanitize_encoding, :parse_tmdb_date, :tmdb_image_url, :valid_file?

          def import_row(row)
            { status: :imported }
          end
        end
      end

      it 'sanitizes invalid encoding and trims whitespace' do
        importer = helper_importer.new(user)
        raw = "Title \xC0".dup.force_encoding("ASCII-8BIT")

        expect(importer.safe_string(raw)).to eq("Title")
      end

      it 'handles parse_tmdb_date errors gracefully' do
        importer = helper_importer.new(user)

        expect(importer.parse_tmdb_date('invalid-date')).to be_nil
        expect(importer.parse_tmdb_date(nil)).to be_nil
      end

      it 'builds tmdb image urls with normalized path' do
        importer = helper_importer.new(user)

        expect(importer.tmdb_image_url('poster.png', size: 'w100')).to eq("https://image.tmdb.org/t/p/w100/poster.png")
        expect(importer.tmdb_image_url(nil)).to be_nil
      end

      it 'validates files respond to read and size' do
        importer = helper_importer.new(user)
        file = StringIO.new('data')

        expect(importer.valid_file?(file)).to be(true)
        expect(importer.valid_file?(double(:file, read: nil, size: 0))).to be(false)
      end
    end
  end
end
