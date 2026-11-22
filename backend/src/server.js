import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

import { initDb, query } from './db.js';
import placesRouter from './routes/places.js';
import searchRouter from './routes/search.js';
import reelsRouter from './routes/reels.js';

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(rateLimit({ windowMs: 60_000, max: 120, standardHeaders: true }));

app.get('/health', async (_req, res) => {
  try {
    await query('SELECT 1');
    res.json({ status: 'ok', db: 'up' });
  } catch {
    res.json({ status: 'ok', db: 'down' });
  }
});

app.get('/api/config', (_req, res) => {
  res.json({
    youtube: Boolean(process.env.YOUTUBE_API_KEY),
    meta: Boolean(process.env.META_OAUTH_TOKEN),
    googlePlaces: Boolean(process.env.GOOGLE_MAPS_API_KEY),
  });
});

app.use('/api/places', placesRouter);
app.use('/api/search', searchRouter);
app.use('/api/reels', reelsRouter);

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'internal server error' });
});

const port = Number(process.env.PORT || 3000);

if (process.env.AUTO_MIGRATE !== 'false') {
  initDb()
    .then(() => console.log('DB schema ready'))
    .catch((err) => console.warn('DB init skipped:', err.message));
}

app.listen(port, () => {
  console.log(`VibeCity API listening on :${port}`);
});