import 'dotenv/config';
import { initDb } from './db.js';

initDb()
  .then(() => {
    console.log('Migration complete.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Migration failed:', err);
    process.exit(1);
  });