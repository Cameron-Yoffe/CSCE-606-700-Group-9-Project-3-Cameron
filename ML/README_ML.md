# Movie Recommendation README

This document captures a practical recommendation approach for the app today (assuming no site data yet) and how it can grow over time. The focus is a **bag-of-entities content-based recommender** that goes richer than “just genres,” plus a lightweight upgrade path.

---

## 1) Core idea: bag-of-entities content model
1) Treat each movie as a sparse feature vector of semantic entities:
    - Genres
    - Director
    - Top N cast
    - Keywords/tags (TMDB keywords or your own)
    - Decade/language/runtime buckets
2) Build a **user taste vector** by averaging feature vectors of movies the user liked (weights can depend on rating).
3) Score unseen movies by similarity to the user vector (dot product or cosine), then rank.

### Movie → feature vector
- Create a global vocabulary like `genre:Drama`, `director:Sofia Coppola`, `cast:Toni Collette`, `keyword:coming-of-age`, `decade:2010s`, etc.
- For each movie, set 1 (or TF-IDF) for each feature it has. Optionally apply per-feature weights, e.g.:

  ```ruby
  FEATURE_WEIGHTS = {
    genre: 1.0,
    director: 2.0,
    cast: 1.5,
    keyword: 2.0,
    decade: 0.5
  }
  ```

### User → taste vector
- Select movies a user liked (e.g., rating ≥ 4 or “liked” flag).
- Weight each movie by preference strength (e.g., `rating - 3`), then compute a weighted average of their vectors.

### Scoring candidates
- For each unseen movie, compute `score = dot(user_vector, movie_vector)` or cosine similarity and rank descending.
- To reduce compute, score a candidate set (e.g., popular unseen movies) instead of every movie.

### Tiny collaborative twist (optional)
- Learn an item–item similarity from all ratings.
- Combine with content score: `final = α * content_score + (1 - α) * max_item_item_similarity`, with `α ≈ 0.7`.

---

## 2) Data you need (now and later)
- **Metadata for features**: genres, director, top cast, keywords/tags, release year → decade buckets, language, runtime bucket.
- **User–item interactions** (future): explicit ratings or likes to build taste vectors; exposure logs help measure bias.
- **Context (future)**: timestamps, session info, device/locale for temporal or session models.

### Bootstrapping sources (no site data yet)
- **TMDb API**: Keywords, cast/crew, genres, images (API key, attribution, rate limits).
- **MovieLens**: Ratings + basic metadata; can be joined with TMDb IDs for richer features.
- **OMDb API**: Alternative metadata source (API key).
- **IMDb non-commercial datasets**: Titles/ratings/crew/genres for research (license restricts commercial use).
- **Kaggle datasets**: Various credits/keywords/ratings; check individual licenses.

### First-party collection (future)
- Ratings/likes, library adds/removes, plays/watch completion, search clicks, impressions (what was shown), and A/B variant labels.

---

## 3) Tech stack and implementation path

### V1 (side-project ready)
- **Rails + PostgreSQL**: Store `movie_embedding` and `user_embedding` as `float[]` or `jsonb`.
- **Background jobs (Sidekiq/ActiveJob)**: Recompute movie vectors on metadata changes; recompute user vectors when ratings/updates occur.
- **Online flow**: Load `user_embedding` → fetch candidate movies (e.g., popular unseen) → compute similarity → sort → return top N.

### V2 (scale up without redesign)
- **pgvector**: Add the extension and query by distance for fast ANN search inside Postgres.
- **Vector service (optional)**: Small Python/FastAPI service holding embeddings in memory; exposes `POST /recommend` for top-N.
- **Hybrid signals**: Concatenate content features with collaborative embeddings (e.g., matrix factorization) and keep the same API: `user_vector`, `movie_vector`, `score`.

### Code hygiene for future growth
- Keep a `Recommender` service with clear entrypoints (e.g., `user_vector`, `movie_vector`, `recommend_for(user)`).
- Separate **candidate generation** from **ranking** so you can later swap in vector search for candidates and a heavier model for ranking.
- Persist embeddings so online requests mostly read cached vectors instead of recomputing.

---

## 4) Governance and quality
- Respect dataset/API licenses (TMDb attribution, IMDb non-commercial limits, Kaggle terms).
- Minimize PII, anonymize IDs, and comply with regional regulations (GDPR/CCPA); honor consent and retention policies.
- Filter bots/abuse, deduplicate events, and monitor for popularity/exposure bias.
- Keep metadata fresh; periodically recompute embeddings and rerun rec jobs with recency-aware weights.

---

## 5) Practical starting point
1. Ingest TMDb metadata (genres, keywords, cast/crew) for the catalog and build movie vectors with the weights above.
2. If experimenting offline, join MovieLens ratings to TMDb metadata to simulate user taste vectors.
3. Implement a Rails `Recommender` that:
    - Builds/stores movie vectors on import/update.
    - Builds user vectors from liked movies (simulated from MovieLens until first-party data exists).
    - Scores a candidate set with dot product or cosine and returns top N.
4. When first-party signals arrive, plug them into the same pipeline and optionally add the item–item similarity blend.
