import { Router } from 'express';
import { query } from '../db.js';

const router = Router();

// GET /api/search?q=
router.get('/', async (req, res, next) => {
  try {
    const q = String(req.query.q || '').trim();
    if (!q) return res.json([]);
    const { rows } = await query(
      `SELECT id, name, category, rating, budget_inr, city, area
         FROM places
        WHERE name ILIKE $1 OR area ILIKE $1 OR category ILIKE $1 OR city ILIKE $1
        ORDER BY rating DESC
        LIMIT 50`,
      [`%${q}%`],
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
});

export default router;