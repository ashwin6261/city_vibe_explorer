import test from 'node:test';
import assert from 'node:assert/strict';

import { searchShorts } from '../src/services/youtube.js';
import { fetchOEmbed } from '../src/services/oembed.js';

test('searchShorts is unconfigured without a key', async () => {
  delete process.env.YOUTUBE_API_KEY;
  const result = await searchShorts('chai', 3);
  assert.equal(result.configured, false);
  assert.deepEqual(result.videos, []);
});

test('fetchOEmbed rejects unsupported URLs', async () => {
  await assert.rejects(
    () => fetchOEmbed('https://example.com/video'),
    /Unsupported URL/,
  );
});