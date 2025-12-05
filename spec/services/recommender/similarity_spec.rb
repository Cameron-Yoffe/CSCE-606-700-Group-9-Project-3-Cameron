require 'rails_helper'

RSpec.describe Recommender::Similarity do
  describe ".dot" do
    it "computes dot product for overlapping features" do
      user_vec = { "genre_action" => 1.0, "genre_comedy" => 0.5 }
      movie_vec = { "genre_action" => 2.0, "genre_drama" => 1.0 }

      result = described_class.dot(user_vec, movie_vec)

      expect(result).to eq(2.0) # 1.0 * 2.0 + 0.5 * 0 = 2.0
    end

    it "returns 0.0 for non-overlapping features" do
      user_vec = { "genre_action" => 1.0 }
      movie_vec = { "genre_drama" => 2.0 }

      result = described_class.dot(user_vec, movie_vec)

      expect(result).to eq(0.0)
    end

    it "returns 0.0 for blank user vector" do
      user_vec = {}
      movie_vec = { "genre_action" => 1.0 }

      result = described_class.dot(user_vec, movie_vec)

      expect(result).to eq(0.0)
    end

    it "returns 0.0 for blank movie vector" do
      user_vec = { "genre_action" => 1.0 }
      movie_vec = {}

      result = described_class.dot(user_vec, movie_vec)

      expect(result).to eq(0.0)
    end

    it "returns 0.0 for nil vectors" do
      result = described_class.dot(nil, nil)

      expect(result).to eq(0.0)
    end
  end

  describe ".cosine" do
    it "returns 1.0 for identical vectors" do
      vec_a = { "a" => 1.0, "b" => 2.0, "c" => 3.0 }
      vec_b = { "a" => 1.0, "b" => 2.0, "c" => 3.0 }

      result = described_class.cosine(vec_a, vec_b)

      expect(result).to be_within(0.0001).of(1.0)
    end

    it "returns 0.0 for orthogonal vectors" do
      vec_a = { "a" => 1.0 }
      vec_b = { "b" => 1.0 }

      result = described_class.cosine(vec_a, vec_b)

      expect(result).to eq(0.0)
    end

    it "returns 0.0 when one vector is empty" do
      vec_a = { "a" => 1.0 }
      vec_b = {}

      result = described_class.cosine(vec_a, vec_b)

      expect(result).to eq(0.0)
    end

    it "handles different magnitude vectors correctly" do
      vec_a = { "a" => 1.0, "b" => 0.0 }
      vec_b = { "a" => 2.0, "b" => 0.0 }

      result = described_class.cosine(vec_a, vec_b)

      expect(result).to be_within(0.0001).of(1.0)
    end
  end

  describe ".magnitude" do
    it "calculates magnitude of a hash vector" do
      vec = { "a" => 3.0, "b" => 4.0 }

      result = described_class.magnitude(vec)

      expect(result).to eq(25.0) # 3^2 + 4^2 = 25 (this returns squared magnitude)
    end

    it "returns 0 for an empty vector" do
      vec = {}

      result = described_class.magnitude(vec)

      expect(result).to eq(0.0)
    end

    it "handles negative values" do
      vec = { "a" => -3.0, "b" => -4.0 }

      result = described_class.magnitude(vec)

      expect(result).to eq(25.0)
    end
  end
end
