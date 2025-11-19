class MoviesController < ApplicationController
  before_action :set_tmdb_client

  def index
    @query = params[:query].to_s.strip
    @results = []

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
