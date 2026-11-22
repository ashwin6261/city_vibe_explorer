// Google Places API (New) — text search for seeding / enrichment.
// Requires GOOGLE_MAPS_API_KEY. Returns [] when not configured.

export async function textSearch(query, { maxResults = 10 } = {}) {
  const key = process.env.GOOGLE_MAPS_API_KEY;
  if (!key) return { configured: false, places: [] };

  const res = await fetch('https://places.googleapis.com/v1/places:searchText', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': key,
      'X-Goog-FieldMask':
        'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.priceLevel,places.primaryType',
    },
    body: JSON.stringify({
      textQuery: query,
      maxResultCount: Math.max(1, Math.min(maxResults, 20)),
    }),
  });
  if (!res.ok) throw new Error(`Google Places ${res.status}`);
  const data = await res.json();

  const places = (data.places || []).map((p) => ({
    googlePlaceId: p.id,
    name: p.displayName?.text ?? '',
    address: p.formattedAddress ?? '',
    lat: p.location?.latitude ?? 0,
    lng: p.location?.longitude ?? 0,
    rating: p.rating ?? 0,
    userRatingsTotal: p.userRatingCount ?? 0,
    priceLevel: p.priceLevel ?? null,
    primaryType: p.primaryType ?? '',
  }));

  return { configured: true, places };
}