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

## Quality checks

Use the helper script to run test/lint suites:

```bash
bin/check
```

This runs RSpec, Cucumber (if present), and `rubocop -a`, skipping any tool that isn't installed in the bundle.
