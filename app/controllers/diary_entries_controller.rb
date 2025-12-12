class DiaryEntriesController < ApplicationController
  before_action :require_login
  before_action :set_diary_entry, only: %i[show edit update destroy]

  def index
    @diary_entries = current_user.diary_entries.includes(:movie).order(watched_date: :desc)
  end

  def show
  end

  def new
    @movie = Movie.find_by(id: params[:movie_id])
    @movies = Movie.order(:title)
    @diary_entry = DiaryEntry.new(watched_date: Date.today)
  end

  def create
    movie_id = params[:diary_entry][:movie_id]
    movie = Movie.find_by(id: movie_id)

    unless movie
      redirect_to diary_entries_path, alert: "Movie not found"
      return
    end

    @diary_entry = current_user.diary_entries.build(diary_entry_params)
    @diary_entry.movie = movie

    if @diary_entry.save
      remove_from_watchlist(movie)
      redirect_to diary_entries_path, notice: "Diary entry created successfully"
    else
      @movie = movie
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @movie = @diary_entry.movie
  end

  def update
    if @diary_entry.update(diary_entry_params)
      redirect_to diary_entries_path, notice: "Diary entry updated successfully"
    else
      @movie = @diary_entry.movie
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @diary_entry.destroy
    redirect_to diary_entries_path, notice: "Diary entry deleted successfully"
  end

  private

  def set_diary_entry
    @diary_entry = current_user.diary_entries.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to diary_entries_path, alert: "Diary entry not found"
  end

  def diary_entry_params
    params.require(:diary_entry).permit(:movie_id, :content, :watched_date, :mood, :rating)
  end

  def require_login
    redirect_to sign_in_path, alert: "You must be logged in" unless logged_in?
  end

  def remove_from_watchlist(movie)
    current_user.watchlists.where(movie_id: movie.id).destroy_all
  end
end
