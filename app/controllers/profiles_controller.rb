class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
    @diary_entries = @user.diary_entries.includes(:movie)

    @diary_count = @diary_entries.count
    @yearly_movies_logged = yearly_diary_entries.count
    @average_rating = calculate_average_rating

    @favorite_genres = top_genres
    @favorite_directors = top_directors

    @max_genre_count = @favorite_genres.map(&:last).max.to_i
    @max_director_count = @favorite_directors.map(&:last).max.to_i

    @monthly_chart_data = build_monthly_chart_data
    @genre_chart_data = build_genre_chart_data

    # Load top 5 movies
    @top_movies = @user.top_movies.includes(:movie)
    @available_favorites = @user.favorites.regular_favorites.includes(:movie).order(created_at: :desc)
  end

  def import_letterboxd
    upload = params[:letterboxd_file]

    unless upload.respond_to?(:read) && upload.respond_to?(:size) && upload.size.to_i.positive?
      return redirect_to profile_path, alert: "Please attach your Letterboxd CSV export before importing."
    end

    file_content = upload.read
    LetterboxdImportJob.perform_later(current_user.id, file_content)

    redirect_to profile_path, notice: "Import started. Your diary will update shortly once processing finishes."
  end

  def import_letterboxd_ratings
    upload = params[:letterboxd_ratings_file]

    unless upload.respond_to?(:read) && upload.respond_to?(:size) && upload.size.to_i.positive?
      return redirect_to profile_path, alert: "Please attach your Letterboxd ratings CSV export before importing."
    end

    file_content = upload.read
    LetterboxdRatingsImportJob.perform_later(current_user.id, file_content)

    redirect_to profile_path, notice: "Import started. Your ratings will update shortly once processing finishes."
  end

  private

  def require_login
    redirect_to sign_up_path, alert: "You must be logged in" unless logged_in?
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :bio, :profile_image_url, :top_5_movies)
  end

  def yearly_diary_entries
    @yearly_diary_entries ||= @diary_entries.where(watched_date: Date.current.beginning_of_year..Date.current.end_of_year)
  end

  def calculate_average_rating
    rating = @user.ratings.average(:value)
    rating ||= @diary_entries.where.not(rating: nil).average(:rating)
    rating&.round(1)
  end

  def top_genres(limit: 5)
    counts = Hash.new(0)

    @diary_entries.each do |entry|
      entry.movie&.genre_names&.each do |genre|
        counts[genre] += 1
      end
    end

    counts.sort_by { |_, count| -count }.first(limit)
  end

  def top_directors(limit: 5)
    counts = Hash.new(0)

    @diary_entries.each do |entry|
      director = entry.movie&.director.to_s.strip
      counts[director] += 1 if director.present?
    end

    counts.sort_by { |_, count| -count }.first(limit)
  end

  def build_monthly_chart_data
    labels = (0..11).map { |i| Date.current.beginning_of_year.advance(months: i).strftime("%b") }
    monthly_counts = Hash.new(0)

    yearly_diary_entries.find_each do |entry|
      label = entry.watched_date.strftime("%b")
      monthly_counts[label] += 1
    end

    {
      labels: labels,
      datasets: [
        {
          label: "Movies logged",
          data: labels.map { |label| monthly_counts[label] },
          backgroundColor: "#4c56ff",
          borderRadius: 8
        }
      ]
    }
  end

  def build_genre_chart_data
    labels = @favorite_genres.map(&:first)
    data = @favorite_genres.map(&:last)
    colors = %w[#4c56ff #ff6a05 #22c55e #a855f7 #0ea5e9 #fbbf24 #ef4444]

    {
      labels: labels,
      datasets: [
        {
          data: data,
          backgroundColor: colors.cycle.take(labels.size),
          borderWidth: 1
        }
      ]
    }
  end
end
