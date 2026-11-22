import 'dotenv/config';
import { initDb, query } from './db.js';

// Starter dataset (Jaipur). Extend freely — the app also reads live Overpass/Google data.
const places = [
  {
    city: 'Jaipur', area: 'Pink City', name: 'Hawa Mahal', category: 'heritage',
    rating: 4.8, budget_inr: 200, is_pure_veg: false, best_time: '9:00 AM – 5:00 PM',
    crowd_status: 'Crowded', must_try: 'Rooftop photography from Wind View Cafe',
    photo_angle_tip: 'Shoot from the Wind View Cafe opposite for a straight-on symmetrical frame.',
    fit_check: 'Great for photos', lat: 26.9239, lng: 75.8267, google_place_id: 'seed_hawa_mahal',
  },
  {
    city: 'Jaipur', area: 'Amer', name: 'Amer Fort', category: 'heritage',
    rating: 4.8, budget_inr: 500, is_pure_veg: false, best_time: '8:00 AM – 5:30 PM',
    crowd_status: 'Crowded', must_try: 'Sheesh Mahal mirror reflections',
    photo_angle_tip: 'Capture the Maota Lake reflection at the front ramparts at golden hour.',
    fit_check: 'Great for photos', lat: 26.9855, lng: 75.8513, google_place_id: 'seed_amer_fort',
  },
  {
    city: 'Jaipur', area: 'Amer Road', name: 'Jal Mahal', category: 'sunset',
    rating: 4.6, budget_inr: 0, is_pure_veg: true, best_time: 'Sunset',
    crowd_status: 'Moderate', must_try: 'Lakeside roasted corn',
    photo_angle_tip: 'Frame the palace between the trees from the promenade for a postcard shot.',
    fit_check: 'Great for photos', lat: 26.9535, lng: 75.8462, google_place_id: 'seed_jal_mahal',
  },
  {
    city: 'Jaipur', area: 'Sindhi Camp', name: 'Rawat Mishthan Bhandar', category: 'chaupati',
    rating: 4.6, budget_inr: 120, is_pure_veg: true, best_time: '6:00 AM – 10:30 PM',
    crowd_status: 'Crowded', must_try: 'Pyaaz Kachori',
    photo_angle_tip: 'Catch the giant kadhai fry in action — shoot at 1/250s to freeze the motion.',
    fit_check: 'Great for food photos', lat: 26.9204, lng: 75.7956, google_place_id: 'seed_rawat',
  },
  {
    city: 'Jaipur', area: 'MI Road', name: 'Lassiwala', category: 'cafe',
    rating: 4.7, budget_inr: 100, is_pure_veg: true, best_time: '7:00 AM – 4:00 PM',
    crowd_status: 'Moderate', must_try: 'Clay kulhad lassi',
    photo_angle_tip: 'Shoot the malai-topped kulhad from a low 45° angle with the shop sign behind.',
    fit_check: 'Great for food photos', lat: 26.9176, lng: 75.8115, google_place_id: 'seed_lassiwala',
  },
];

async function main() {
  await initDb();
  for (const p of places) {
    await query(
      `INSERT INTO places
         (city, area, name, category, google_place_id, rating, budget_inr, is_pure_veg,
          best_time, crowd_status, must_try, photo_angle_tip, fit_check, lat, lng, coords)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,
               ST_SetSRID(ST_MakePoint($15,$14),4326)::geography)
       ON CONFLICT (google_place_id) DO NOTHING`,
      [
        p.city, p.area, p.name, p.category, p.google_place_id, p.rating, p.budget_inr,
        p.is_pure_veg, p.best_time, p.crowd_status, p.must_try, p.photo_angle_tip,
        p.fit_check, p.lat, p.lng,
      ],
    );
  }
  console.log(`Seeded ${places.length} places.`);
  process.exit(0);
}

main().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});