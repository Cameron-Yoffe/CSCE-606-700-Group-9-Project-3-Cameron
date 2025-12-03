class MoviesController < ApplicationController
  before_action :set_tmdb_client

  def index
    @query = params[:query].to_s.strip
    search_query = params[:search].to_s.strip
    @results = []

    # Handle JSON requests for search
    if request.format.json?
      if search_query.present?
        # Search TMDB API instead of local database
        if @tmdb_client
          begin
            tmdb_results = search_movies(search_query)
            # Convert TMDB results to a consistent format
            movies = tmdb_results.map do |result|
              {
                id: result["id"],
                tmdb_id: result["id"],
                title: result["title"],
                poster_url: result["poster_path"] ? "https://image.tmdb.org/t/p/w500#{result["poster_path"]}" : nil,
                release_date: result["release_date"]
              }
            end
            render json: { movies: movies }
          rescue Tmdb::Error => e
            render json: { movies: [], error: e.message }, status: :service_unavailable
          end
        else
          render json: { movies: [], error: "TMDB API not available" }, status: :service_unavailable
        end
      else
        render json: { movies: [] }
      end
      return
    end

    return if @query.blank? && !params.key?(:query)

    if @query.blank?
      flash.now[:alert] = "Please enter a movie title to search."
      return
    end

    @results = search_movies(@query)
  rescue Tmdb::Error => e
    flash.now[:alert] = e.message
  end

  def show
    @movie = @tmdb_client.movie(params[:id], append_to_response: "credits")
  rescue Tmdb::Error => e
    redirect_to movies_path, alert: e.message
  end

  private

  def set_tmdb_client
    @tmdb_client = Tmdb::Client.new
  rescue Tmdb::AuthenticationError => e
    # If the TMDB API key is missing or invalid, don't raise an exception that breaks the app.
    # Instead, surface a friendly alert and leave @tmdb_client nil so views can handle absence.
    @tmdb_client = nil
    flash.now[:alert] = e.message
  end

  def search_movies(query)
    response = @tmdb_client.get("/search/movie", query: query, include_adult: false)
    Array(response.fetch("results", [])).first(10)
  end
end
