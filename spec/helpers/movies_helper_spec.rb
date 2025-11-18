require "rails_helper"

RSpec.describe MoviesHelper, type: :helper do
  describe "#poster_url" do
    it "returns a placeholder when path is blank" do
      expect(helper.poster_url(nil)).to eq("https://placehold.co/300x450?text=No+Image")
      expect(helper.poster_url(" ")).to eq("https://placehold.co/300x450?text=No+Image")
    end

    it "builds the TMDB image URL preserving the /t/p path" do
      expect(helper.poster_url("/abc123.jpg", size: "w185")).to eq("https://image.tmdb.org/t/p/w185/abc123.jpg")
    end

    it "adds a leading slash when missing" do
      expect(helper.poster_url("xyz.png", size: "original")).to eq("https://image.tmdb.org/t/p/original/xyz.png")
    end
  end

  describe "#director_name" do
    it "returns the director from credits" do
      movie = { "credits" => { "crew" => [
        { "job" => "Director", "name" => "David Fincher" },
        { "job" => "Producer", "name" => "Art Linson" }
      ] } }

      expect(helper.director_name(movie)).to eq("David Fincher")
    end

    it "returns N/A when no director information is available" do
      expect(helper.director_name({})).to eq("N/A")
    end
  end
end
