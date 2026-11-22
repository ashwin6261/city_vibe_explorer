import { Router } from 'express';
import { query } from '../db.js';

const router = Router();

// GET /api/places/nearby?lat=&lng=&radius=&limit=
router.get('/nearby', async (req, res, next) => {
  try {
    const lat = Number.parseFloat(req.query.lat);
    const lng = Number.parseFloat(req.query.lng);
    const radius = Math.min(Number.parseFloat(req.query.radius) || 2000, 50000);
    const limit = Math.min(Number.parseInt(req.query.limit, 10) || 50, 200);

    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return res.status(400).json({ error: 'lat and lng are required' });
    }

    const { rows } = await query(
      `SELECT id, city, area, name, category, rating, food_rating, budget_inr,
              is_pure_veg, best_time, crowd_status, must_try, photo_angle_tip, fit_check,
              ST_Distance(coords, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography) AS distance_m
         FROM places
        WHERE ST_DWithin(coords, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography, $3)
        ORDER BY distance_m ASC
        LIMIT $4`,
      [lat, lng, radius, limit],
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
});

// GET /api/places/:id  -> place + its reels
router.get('/:id', async (req, res, next) => {
  try {
    const { rows } = await query('SELECT * FROM places WHERE id = $1', [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'place not found' });
    const reels = await query(
      'SELECT * FROM place_reels WHERE place_id = $1 ORDER BY created_at DESC',
      [req.params.id],
    );
    res.json({ ...rows[0], reels: reels.rows });
  } catch (err) {
    next(err);
  }
});

export default router;