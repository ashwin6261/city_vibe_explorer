// oEmbed proxy: converts a public video URL into a policy-compliant embed.
// Keeps META_OAUTH_TOKEN server-side (never shipped in the APK).
//   - YouTube: public oEmbed (no key needed)
//   - Instagram / Facebook: Meta oEmbed (requires META_OAUTH_TOKEN)

function platformOf(hostname) {
  if (hostname.includes('youtube.com') || hostname === 'youtu.be') return 'YouTube';
  if (hostname.includes('instagram.com')) return 'Instagram';
  if (hostname.includes('facebook.com') || hostname.includes('fb.watch')) return 'Facebook';
  return null;
}

export async function fetchOEmbed(rawUrl) {
  const url = new URL(rawUrl);
  const platform = platformOf(url.hostname);
  if (!platform) {
    throw new Error('Unsupported URL');
  }

  if (platform === 'YouTube') {
    const endpoint = `https://www.youtube.com/oembed?url=${encodeURIComponent(
      rawUrl,
    )}&format=json`;
    const res = await fetch(endpoint);
    if (!res.ok) throw new Error(`YouTube oEmbed ${res.status}`);
    const j = await res.json();
    return {
      platform,
      title: j.title,
      thumbnail: j.thumbnail_url,
      html: j.html,
      author: j.author_name,
    };
  }

  // Instagram / Facebook — Meta oEmbed
  const token = process.env.META_OAUTH_TOKEN;
  if (!token) {
    return {
      platform,
      url: rawUrl,
      html: null,
      thumbnail: null,
      author: null,
      note: 'Meta oEmbed token not configured',
    };
  }

  const graph = platform === 'Instagram'
    ? 'https://graph.facebook.com/v21.0/instagram_oembed'
    : 'https://graph.facebook.com/v21.0/oembed_post';
  const endpoint = `${graph}?url=${encodeURIComponent(rawUrl)}&access_token=${token}`;
  const res = await fetch(endpoint);
  if (!res.ok) throw new Error(`Meta oEmbed ${res.status}`);
  const j = await res.json();
  return {
    platform,
    title: j.title ?? null,
    thumbnail: j.thumbnail_url ?? null,
    html: j.html ?? null,
    author: j.author_name ?? null,
  };
}