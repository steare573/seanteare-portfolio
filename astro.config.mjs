// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// Served from the apex domain via CloudFront, so there is no path prefix and
// `base` is intentionally absent. Internal links go through src/lib/paths.ts,
// which collapses to a no-op when BASE_URL is "/".
export default defineConfig({
  site: 'https://seanteare.com',
  trailingSlash: 'ignore',
  build: {
    format: 'directory',
  },
  // Emits sitemap-index.xml and sitemap-0.xml. Submit the index to Search
  // Console; public/robots.txt advertises it to everything else.
  //
  // No `filter` needed, which is worth stating because its absence looks like
  // an oversight. 404 is excluded by the integration itself, and draft posts
  // never reach it because getStaticPaths in blog/[...slug].astro drops them
  // from production builds before the sitemap sees the route list. Both are
  // asserted in the build output rather than assumed.
  integrations: [sitemap()],
});
