// @ts-check
import { defineConfig } from 'astro/config';

// Served from the apex domain via CloudFront, so there is no path prefix and
// `base` is intentionally absent. Internal links go through src/lib/paths.ts,
// which collapses to a no-op when BASE_URL is "/".
export default defineConfig({
  site: 'https://seanteare.com',
  trailingSlash: 'ignore',
  build: {
    format: 'directory',
  },
});
