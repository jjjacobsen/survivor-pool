<!-- markdownlint-disable MD033 -->
<div align="center">
  <h1>Survivor Pool</h1>
  <p><strong>Pick'em strategy game for the TV show Survivor.</strong><br/>Built to stretch my Flutter skills, experiment with a FastAPI backend, and ship something fun for friends.</p>
  <p>
    <img src="https://img.shields.io/badge/Flutter-3.35-02569b?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/FastAPI-0.115-109989?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI" />
    <img src="https://img.shields.io/badge/MongoDB-Developer%20Data-4caf50?style=for-the-badge&logo=mongodb&logoColor=white" alt="MongoDB" />
    <img src="https://img.shields.io/badge/Docker-Compose-2496ed?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" />
  </p>
  <p>
    <a href="docs/PRD.md">Product spec</a>
    ·
    <a href="docs/DB_schema.md">Database schema</a>
    ·
    <a href="db/seasons">Seed data</a>
  </p>
</div>
<!-- markdownlint-enable MD033 -->

---

## Table of Contents

- [Why It Exists](#why-it-exists)
- [Game Highlights](#game-highlights)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Architecture Snapshot](#architecture-snapshot)
- [Security](#security)
- [Project Layout](#project-layout)
- [Shoutouts](#shoutouts)

## Why It Exists

- 🎯 Showcase of full-stack Flutter + FastAPI work
- 🧠 Space to practice product thinking, not just TODO apps
- 🧑‍🤝‍🧑 Built for my Survivor group so we can talk trash each week

## Game Highlights

- ✅ Weekly picks with no-repeat rules and instant eliminations
- 📊 Live leaderboards powered by cached pick availability
- 🧭 Pool owners control their seasons, contestants, and eliminations
- 🔄 Season data is treated as TV canon and reused across every pool

## Tech Stack

- **Flutter** for a single codebase across web and mobile
- **FastAPI** service with JWT auth, routing, and CORS baked in
- **MongoDB** schema built for immutable TV facts plus fast leaderboards
- **Docker Compose** plus `mise` tasks (with `uv` for backend deps) to launch everything quickly

## Getting Started

Install Homebrew first: [brew.sh](https://brew.sh)

```bash
brew install mise uv pyright prettier pre-commit
```

```bash
# install tool versions from mise.toml
mise install

# install project dependencies
mise bootstrap

# run everything (MongoDB + backend + frontend) inside tmux
mise dev

# or drive services individually
mise mongo
mise backend
mise frontend
```

- Default Flutter target is iOS, but you can switch with `flutter run -d web-server` or any connected device.
- `mise bootstrap` wires up Flutter packages and uses `uv` to sync backend requirements.
- `mise attach` drops you into the dev tmux session; `mise stop` shuts everything down cleanly.

### Environment config

- `.env.dev` and `.env.prod` live in the repo root and only carry backend settings (Mongo URL, DB name, CORS rule).
- The `backend` task in `mise.toml` loads `.env.dev`, so `mise backend` (and `mise dev`, which shells into that task) get their env from that file; other tasks run clean.
- `mise prod` delegates to Docker Compose, whose backend service references `.env.prod` through `env_file`, so production containers read the same values.
- `mise db-update -- --dev|--prod` seeds Mongo using the matching env file.
- don't put secrets in frontend

## Architecture Snapshot

- 🎨 **Frontend**: Flutter app lives in `frontend/survivor_pool`, designed mobile-first with web support.
- ⚙️ **Backend**: FastAPI service (`backend/src`) coordinates game rules, picks, and pool logic.
- 🗃️ **Database**: MongoDB holds normalized pool data while seasons stay immutable in per-season files under `db/seasons` loaded by `db/init.js`.
- 🔌 **APIs**: REST endpoints grouped by domain (`pools`, `picks`, `seasons`, `users`) with strict CORS configuration.

## Security

- ✅ `semgrep scan` was run to find and fix security vulnerabilities; rerun it after meaningful backend changes.

## Project Layout

```text
.
├── frontend/          # Flutter application
├── backend/           # FastAPI service and routers
├── db/                # Mongo seed scripts + season canon
└── docs/              # PRD + database design notes
```

## Shoutouts

- 🙌 Thanks to my Survivor crew for the constant feature requests.
- 📺 Inspired by the real show format—every twist keeps the product fun.
