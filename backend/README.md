# VibeCity Backend API

Geospatial places + short-form social reels API for the VibeCity Android app.
Built with **Node.js 20 + Express + PostgreSQL/PostGIS**.

## Features
- `places` / `place_reels` tables with PostGIS radius queries ("chaupati stalls within 2 km").
- Live **YouTube Shorts** search (YouTube Data API v3).
- **oEmbed proxy** for Instagram / Facebook / YouTube (keeps `META_OAUTH_TOKEN` server-side).
- Optional **Google Places (New)** text search for seeding/enrichment.
- Docker + Render blueprint for one-click deployment.

## Local setup
```bash
cd backend
cp .env.example .env        # edit DATABASE_URL + optional keys
npm install
npm run migrate             # create PostGIS tables
npm run seed                # insert starter Jaipur places
npm start                   # http://localhost:3000
```

> Requires a PostgreSQL instance with the **PostGIS** extension (local Postgres,
> or a free Neon/Supabase/Render Postgres).

## API
| Method | Endpoint | Description |
|---|---|---|
| GET | `/health` | Liveness + DB status |
| GET | `/api/config` | Which optional keys are configured |
| GET | `/api/places/nearby?lat=&lng=&radius=&limit=` | Places within radius, sorted by distance |
| GET | `/api/places/:id` | Place detail + its reels |
| GET | `/api/search?q=` | Name/area/category search (rating desc) |
| GET | `/api/reels/trending?lat=&lng=&radius=` | Reels near a location |
| GET | `/api/reels/youtube?q=&max=` | Live YouTube Shorts for a place |
| POST | `/api/reels/oembed` | `{ "url": "..." }` → embed payload |

### Example
```bash
curl "http://localhost:3000/api/places/nearby?lat=26.9196&lng=75.8115&radius=2000"
curl "http://localhost:3000/api/reels/youtube?q=Hawa%20Mahal%20shorts&max=5"
curl -X POST http://localhost:3000/api/reels/oembed \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://www.youtube.com/watch?v=dQw4w9WgXcQ"}'
```

## Deploy (Render)
1. Push this repo to GitHub.
2. In Render: **New → Blueprint** → select the repo → it reads the repo-root **`render.yaml`**.
3. Render provisions a **Postgres (PostGIS)** database, the **Dockerized API** (`vibecity-api`), and the **PWA** (`vibecity-web`) automatically.
4. Add optional `YOUTUBE_API_KEY`, `META_OAUTH_TOKEN`, `GOOGLE_MAPS_API_KEY` in the dashboard to enable live data.
5. Deploy — health check at `/health`. The schema auto-creates on boot (`AUTO_MIGRATE=true`); run `npm run seed` in the Render Shell to load starter places.

## Environment
| Var | Required | Purpose |
|---|---|---|
| `DATABASE_URL` | ✅ | Postgres connection string |
| `DATABASE_SSL` | ➖ | `true` for managed Postgres (Render/Neon) |
| `YOUTUBE_API_KEY` | ➖ | YouTube Data API v3 (Shorts) |
| `META_OAUTH_TOKEN` | ➖ | Meta oEmbed (IG/FB reels) |
| `GOOGLE_MAPS_API_KEY` | ➖ | Google Places (New) enrichment |

## Test
```bash
npm test
```