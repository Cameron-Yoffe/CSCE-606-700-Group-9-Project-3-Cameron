# README

## Development setup

Run everything with a single command:

```bash
bin/setup
```

This installs Ruby gems, installs npm packages (for Tailwind), prepares the database, clears temp files, and boots the dev server (pass `--skip-server` to omit running `bin/dev`).

To start the app later, simply run:

```bash
bin/dev
```

Foreman will read `Procfile.dev` and run both the Rails server (`web`) and Tailwind watcher (`css`) so everyone has the same workflow.

### TMDB configuration

The movie search feature depends on a TMDB API key. You can configure it in one of two ways:

* Set the `TMDB_API_KEY` environment variable (e.g., add it to your shell profile or `.env.local`).
* Add credentials via `bin/rails credentials:edit` using the `tmdb.api_key` path. (alt command: `EDITOR=vim bin/rails credentials:edit`)

Format the credentials file like so:

```yaml
tmdb:
  api_key: your_tmdb_api_key_here
```

## Quality checks

Use the helper script to run test/lint suites:

```bash
bin/check
```

This runs RSpec, Cucumber (if present), and `rubocop -a`, skipping any tool that isn't installed in the bundle.
