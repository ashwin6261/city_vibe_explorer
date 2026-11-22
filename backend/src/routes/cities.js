import { Router } from 'express';
import { INDIA_CITIES } from '../data/india-cities.js';

const router = Router();

// GET /api/cities?q=&limit=
// Returns Indian states + major cities/towns from the bundled dataset, and
// falls back to live Nominatim search so any town/village in India is covered.
router.get('/', async (req, res, next) => {
  try {
    const q = String(req.query.q || '').trim().toLowerCase();
    const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);

    let results;
    if (!q) {
      results = [
        ...INDIA_CITIES.filter((c) => c.type === 'state' || c.type === 'union'),
        ...INDIA_CITIES.filter((c) => c.type === 'city').slice(0, 40),
      ];
    } else {
      results = INDIA_CITIES.filter(
        (c) =>
          c.name.toLowerCase().includes(q) || c.state.toLowerCase().includes(q),
      ).slice(0, limit);
    }

    // Live fallback for towns/villages not in the bundled list.
    if (q && results.length < limit) {
      const live = await liveSearch(q, limit - results.length);
      const seen = new Set(results.map((r) => r.name.toLowerCase()));
      for (const item of live) {
        if (!seen.has(item.name.toLowerCase())) {
          results.push(item);
          seen.add(item.name.toLowerCase());
        }
      }
    }

    res.json(results.slice(0, limit));
  } catch (err) {
    next(err);
  }
});

async function liveSearch(q, limit) {
  if (limit <= 0) return [];
  try {
    const url =
      `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(q + ', India')}` +
      `&format=json&limit=${limit}&addressdetails=1`;
    const r = await fetch(url, {
      headers: { 'User-Agent': 'VibeCityBackend/1.0 (city explorer)' },
    });
    if (!r.ok) return [];
    const data = await r.json();
    return data.map((d) => ({
      name: String(d.display_name || '').split(',')[0].trim() || q,
      state: d.address?.state || d.address?.country || 'India',
      lat: Number.parseFloat(d.lat),
      lng: Number.parseFloat(d.lon),
      type: d.type || 'place',
    }));
  } catch {
    return [];
  }
}

export default router;