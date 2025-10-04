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
    <a href="db/init/init.js">Seed data</a>
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

```bash
# install tool versions from mise.toml
mise install

# install project dependencies
mise run bootstrap

# run everything (MongoDB + backend + frontend) inside tmux
mise run start

# or drive services individually
mise run mongo
mise run backend
mise run frontend
```

- Default Flutter target is iOS, but you can switch with `flutter run -d web-server` or any connected device.
- `mise run bootstrap` wires up Flutter packages and uses `uv` to sync backend requirements.
- `mise attach` drops you into the dev tmux session; `mise run stop` shuts everything down cleanly.

## Architecture Snapshot

- 🎨 **Frontend**: Flutter app lives in `frontend/survivor_pool`, designed mobile-first with web support.
- ⚙️ **Backend**: FastAPI service (`backend/src`) coordinates game rules, picks, and pool logic.
- 🗃️ **Database**: MongoDB holds normalized pool data while seasons stay immutable inside a single document (`db/init/init.js`).
- 🔌 **APIs**: REST endpoints grouped by domain (`pools`, `picks`, `seasons`, `users`) with strict CORS configuration.

## Project Layout

```text
.
├── frontend/          # Flutter application
├── backend/           # FastAPI service and routers
├── db/init/           # Mongo seed scripts and season canon data
├── docs/              # PRD + database design notes
└── scripts/           # Dev utilities (tmux, Mongo shell helpers)
```

## Shoutouts

- 🙌 Thanks to my Survivor crew for the constant feature requests.
- 📺 Inspired by the real show format—every twist keeps the product fun.
