import pg from 'pg';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const { Pool } = pg;
const __dirname = dirname(fileURLToPath(import.meta.url));

const connectionString = process.env.DATABASE_URL;
const useSsl =
  process.env.DATABASE_SSL === 'true' ||
  Boolean(connectionString && connectionString.includes('sslmode=require'));

const pool = connectionString
  ? new Pool({
      connectionString,
      ssl: useSsl ? { rejectUnauthorized: false } : undefined,
    })
  : new Pool({
      host: process.env.PGHOST || 'localhost',
      port: Number(process.env.PGPORT || 5432),
      user: process.env.PGUSER || 'postgres',
      password: process.env.PGPASSWORD || 'postgres',
      database: process.env.PGDATABASE || 'vibecity',
    });

export function query(text, params) {
  return pool.query(text, params);
}

export async function initDb() {
  const schema = readFileSync(join(__dirname, 'schema.sql'), 'utf8');
  await pool.query(schema);
}

export default pool;