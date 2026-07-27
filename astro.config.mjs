// @ts-check
import { defineConfig } from 'astro/config';

// Deployed as a GitHub Pages *project* site, so every URL is prefixed with the
// repo name. If you later point a custom domain at this, drop `base` and set
// `site` to the domain — internal links go through src/lib/paths.ts, so that is
// the only change needed.
export default defineConfig({
  site: 'https://steare573.github.io',
  base: '/seanteare-portfolio',
  trailingSlash: 'ignore',
  build: {
    format: 'directory',
  },
});
