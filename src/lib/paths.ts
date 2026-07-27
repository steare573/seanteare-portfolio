/**
 * Internal-link helpers.
 *
 * The site deploys to a GitHub Pages project URL, so every path is prefixed
 * with `base` from astro.config.mjs. Routing all internal hrefs through here
 * means switching to a custom domain is a one-line config change rather than a
 * find-and-replace across every template.
 */

const BASE = import.meta.env.BASE_URL.replace(/\/+$/, '');

/** Build an internal href: path('/resume') -> '/seanteare-portfolio/resume' */
export function path(p = '/'): string {
  const rel = p.startsWith('/') ? p : `/${p}`;
  return `${BASE}${rel}` || '/';
}

/**
 * Top-level section for the current URL, used for nav highlighting.
 * '/blog/some-post' and '/blog' both resolve to 'blog'.
 */
export function sectionOf(pathname: string): string {
  const stripped = pathname.startsWith(BASE) ? pathname.slice(BASE.length) : pathname;
  const [first] = stripped.split('/').filter(Boolean);
  return first ?? 'home';
}

/** "March 2025" — the display format the design uses throughout. */
export function monthYear(date: Date): string {
  return date.toLocaleDateString('en-US', {
    month: 'long',
    year: 'numeric',
    timeZone: 'UTC',
  });
}
