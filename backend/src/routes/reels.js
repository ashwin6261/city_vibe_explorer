import { Router } from 'express';
import { query } from '../db.js';
import { fetchOEmbed } from '../services/oembed.js';
import { searchShorts } from '../services/youtube.js';

const router = Router();

// GET /api/reels/trending?lat=&lng=&radius=
router.get('/trending', async (req, res, next) => {
  try {
    const lat = Number.parseFloat(req.query.lat);
    const lng = Number.parseFloat(req.query.lng);
    const radius = Math.min(Number.parseFloat(req.query.radius) || 5000, 50000);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return res.status(400).json({ error: 'lat and lng are required' });
    }
    const { rows } = await query(
      `SELECT r.*, p.name AS place_name, p.lat, p.lng,
              ST_Distance(p.coords, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography) AS distance_m
         FROM place_reels r
         JOIN places p ON p.id = r.place_id
        WHERE ST_DWithin(p.coords, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography, $3)
        ORDER BY distance_m ASC
        LIMIT 50`,
      [lat, lng, radius],
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
});

// POST /api/reels/oembed  { url }  -> embed payload (tokens stay server-side)
router.post('/oembed', async (req, res, next) => {
  try {
    const url = String(req.body?.url || '').trim();
    if (!url) return res.status(400).json({ error: 'url is required' });
    const embed = await fetchOEmbed(url);
    res.json(embed);
  } catch (err) {
    res.status(502).json({ error: 'oembed failed', detail: String(err.message || err) });
  }
});

// GET /api/reels/youtube?q=&max=  -> live YouTube Shorts for a place
router.get('/youtube', async (req, res, next) => {
  try {
    const q = String(req.query.q || '').trim();
    if (!q) return res.status(400).json({ error: 'q is required' });
    const max = Number.parseInt(req.query.max, 10) || 5;
    const result = await searchShorts(q, max);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

export default router;