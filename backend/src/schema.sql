-- VibeCity geospatial schema (PostgreSQL + PostGIS)
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS places (
    id SERIAL PRIMARY KEY,
    city VARCHAR(100) NOT NULL,
    area VARCHAR(150) NOT NULL,
    name VARCHAR(200) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'chaupati', 'cafe', 'sunset', 'heritage', 'shopping', 'nightlife'
    google_place_id VARCHAR(255) UNIQUE,
    rating DECIMAL(2,1) DEFAULT 4.5,
    food_rating DECIMAL(2,1) DEFAULT 4.5,
    budget_inr INT DEFAULT 150,
    is_pure_veg BOOLEAN DEFAULT TRUE,
    best_time VARCHAR(100),
    crowd_status VARCHAR(100),
    must_try TEXT,
    photo_angle_tip TEXT,
    fit_check VARCHAR(150),
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    coords GEOGRAPHY(POINT, 4326),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS place_reels (
    id SERIAL PRIMARY KEY,
    place_id INT REFERENCES places(id) ON DELETE CASCADE,
    platform VARCHAR(20) NOT NULL, -- 'IG Reel', 'FB Reel', 'YT Short'
    creator_handle VARCHAR(100),
    reel_url TEXT NOT NULL,
    embed_html TEXT,
    thumbnail_url TEXT,
    caption TEXT,
    audio_track VARCHAR(150),
    views_count VARCHAR(50),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Spatial index for instant "near me" radius queries
CREATE INDEX IF NOT EXISTS idx_places_coords ON places USING GIST (coords);
CREATE INDEX IF NOT EXISTS idx_place_reels_place ON place_reels (place_id);