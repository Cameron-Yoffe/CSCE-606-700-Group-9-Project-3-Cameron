class WatchlistsController < ApplicationController
  before_action :require_login

  def create
    tmdb_id = params[:tmdb_id] || params.dig(:movie, :tmdb_id)
    title = params[:title] || params.dig(:movie, :title)
    poster_url_param = params[:poster_url].presence

    if tmdb_id.blank?
      respond_to do |format|
        format.html { redirect_back fallback_location: movies_path, alert: "Missing movie id" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: "Missing movie id" }) }
      end
      return
    end

    movie = Movie.find_or_create_by(tmdb_id: tmdb_id.to_i) do |m|
      m.title = title.presence || "Untitled"
      m.poster_url = poster_url_param if poster_url_param.present?
    end

    if poster_url_param.present? && movie.poster_url.blank?
      movie.update(poster_url: poster_url_param)
    end

    watchlist = current_user.watchlists.find_or_create_by(movie: movie)
    @watchlist = watchlist

    respond_to do |format|
      format.html do
        if watchlist.persisted?
          redirect_back fallback_location: movies_path, notice: "Added to your library"
        else
          redirect_back fallback_location: movies_path, alert: "Could not add to library"
        end
      end
      format.turbo_stream do
        if watchlist.persisted?
          render :create
        else
          render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: "Could not add to library" })
        end
      end
    end
  end

  def destroy
    watchlist = current_user.watchlists.find_by(id: params[:id])

    unless watchlist
      respond_to do |format|
        format.html { redirect_back fallback_location: dashboard_path, alert: "Item not found in your library" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: "Item not found in your library" }) }
      end
      return
    end

    movie = watchlist.movie
    wl_id = watchlist.id

    # Also remove the associated rating when removing from library
    current_user.ratings.find_by(movie_id: movie.id)&.destroy

    watchlist.destroy

    respond_to do |format|
      format.html { redirect_back fallback_location: dashboard_path, notice: "Removed from your library" }
      format.turbo_stream { render :destroy, locals: { movie: movie, watchlist_id: wl_id } }
    end
  end

  private

  def require_login
    redirect_to sign_up_path, alert: "You must be logged in" unless logged_in?
  end
end
