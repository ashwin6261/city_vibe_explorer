// YouTube Data API v3 — search public Shorts for a place.
// Requires YOUTUBE_API_KEY. Without a key, returns { configured:false, videos:[] }.

export async function searchShorts(query, maxResults = 5) {
  const key = process.env.YOUTUBE_API_KEY;
  if (!key) return { configured: false, videos: [] };

  const url = new URL('https://www.googleapis.com/youtube/v3/search');
  url.searchParams.set('part', 'snippet');
  url.searchParams.set('q', query);
  url.searchParams.set('type', 'video');
  url.searchParams.set('videoDuration', 'short');
  url.searchParams.set('maxResults', String(Math.max(1, Math.min(maxResults, 50))));
  url.searchParams.set('key', key);

  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`YouTube API ${res.status}`);
  }
  const data = await res.json();

  const videos = (data.items || [])
    .filter((it) => it.id && it.id.videoId)
    .map((it) => ({
      platform: 'YouTube Short',
      videoId: it.id.videoId,
      url: `https://www.youtube.com/shorts/${it.id.videoId}`,
      title: it.snippet?.title ?? '',
      thumbnail:
        it.snippet?.thumbnails?.high?.url ||
        it.snippet?.thumbnails?.medium?.url ||
        it.snippet?.thumbnails?.default?.url ||
        `https://img.youtube.com/vi/${it.id.videoId}/hqdefault.jpg`,
      creator: it.snippet?.channelTitle ?? '',
      publishedAt: it.snippet?.publishedAt ?? null,
    }));

  return { configured: true, videos };
}