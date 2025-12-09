# Technical Documentation

This document explains how to go from a fresh clone to a deployed of the Movie Diary app.

## Prerequisites
- Ruby 3.4.5 (see `.ruby-version`)
- Node.js 20+ and npm (for Tailwind builds)
- SQLite (default), or configure another Rails-supported database
- Bundler (`gem install bundler`)
- TMDB API key for search/recommendations
  - Use this key for easier grading: 9ee1e9af5ccf586991e69709215e4740

## Local setup (zero to running)
1. **Clone and install**
   ```bash
   git clone <https://github.com/tamu-edu-students/CSCE-606-700-Group-9-Project-3.git>
   cd CSCE-606-700-Group-9-Project-3
   bin/setup
   ```
   The setup task installs gems, installs npm packages, prepares the database, and boots the dev server unless `--skip-server` is supplied.

2. **Configure TMDB**
    - Set `TMDB_API_KEY` in your shell (or `.env.local`), **or** add it via `bin/rails credentials:edit` under `tmdb.api_key`.
3. **Run the app**
   ```bash
   bin/dev
   ```
   Foreman reads `Procfile.dev` to run the Rails server and Tailwind watcher together.
4. **Quality checks**
   ```bash
   bin/check
   ```
   Runs RuboCop, RSpec, and Cucumber with SimpleCov coverage.

## Deployment
- Deployment is available at https://movie-diary-1b90beb60a9f.herokuapp.com/

## Architecture
- **Diagrams**: High level and data models live in `docs/Technical Documentation/Diagrams/`

## User Stories
- User stories live in the Github issues and projects 