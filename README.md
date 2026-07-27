# seanteare-portfolio

Personal portfolio and blog for Sean Teare. Built with [Astro](https://astro.build) —
static output, zero JavaScript shipped to the browser.

## Quick start

```bash
npm install
npm run dev      # http://localhost:4321/seanteare-portfolio
```

| Command | Does |
|---|---|
| `npm run dev` | Dev server with hot reload |
| `npm run build` | Static build into `dist/` |
| `npm run preview` | Serve `dist/` exactly as it will deploy |
| `npm run check` | Type-check `.astro` and `.ts` files |

Requires Node 18.20+, 20.3+, or 22+. This repo was built against Node 22/24.

## Adding a blog post

Create a markdown file in `src/content/blog/`. The filename is the URL slug —
`src/content/blog/my-post.md` becomes `/blog/my-post`.

```markdown
---
title: "Your Title Here"
excerpt: "One or two sentences. Shown on the blog index and used as the meta description."
tag: "Platform Engineering"
date: 2026-08-14
readTime: "5 min read"
---

Write the body in normal markdown. Headings, lists, code blocks, blockquotes,
and images are all styled — see the `.prose` rules in `src/styles/site.css`.
```

That's the whole workflow. The blog index and the post page both build themselves
from the collection, newest first. No registration step, no config edit.

Frontmatter is validated against a Zod schema in `src/content.config.ts`, so a
missing or misspelled field **fails the build** rather than rendering an empty
slot. Add `draft: true` to keep a post visible in `npm run dev` but excluded from
production builds.

## Layout

```
src/
  pages/                 file-based routing — one file, one URL
    index.astro          /
    resume.astro         /resume
    contact.astro        /contact
    blog/index.astro     /blog
    blog/[...slug].astro /blog/<slug>  (one page per markdown file)
  content/blog/*.md      the posts themselves
  content.config.ts      frontmatter schema
  data/resume.ts         skills, stats, roles, full job history, profile text
  layouts/Base.astro     <head>, meta tags, nav + footer wrapper
  components/            Nav, Footer, Icon
  styles/
    design-system.css    tokens, @font-face, component classes
    site.css             base styles + .prose (markdown) styling
  assets/                fonts and images processed by the build
  lib/paths.ts           internal-link + date helpers
public/                  copied verbatim; put the résumé PDF here
```

## Where to edit

| Change | Where |
|---|---|
| Colors, type scale, spacing | `src/styles/design-system.css` — `:root` block |
| Heading font | `src/styles/design-system.css` — `--font-heading`, three presets documented inline |
| Skills, stats, job history | `src/data/resume.ts` |
| Blog posts | `src/content/blog/*.md` |
| Page copy and structure | the matching file in `src/pages/` |
| Nav links | `src/components/Nav.astro` |

The palette runs on a small set of tokens (`--color-bg`, `--color-accent`,
`--color-accent-2`, …) with OKLCH-derived tonal ramps. Retune those and the whole
site moves together.

## Deploying

Pushing to `main` triggers `.github/workflows/deploy.yml`, which builds and
publishes to GitHub Pages.

**One-time setup:** Settings → Pages → Source → **GitHub Actions**.

The site deploys as a project page, so every URL is prefixed with the repo name.
That prefix comes from `base` in `astro.config.mjs`, and all internal links go
through `path()` in `src/lib/paths.ts`. To move to a custom domain: drop `base`,
set `site` to the domain, and add a `CNAME` file to `public/`. No template edits.

`public/.nojekyll` is required — Astro emits a `_astro/` directory and Jekyll
strips underscore-prefixed paths.

## Known gaps

- **The résumé Download PDF button 404s.** `public/Sean-Teare-Resume.pdf` does not
  exist yet. Drop the file there and the button works — no code change. This link
  was already dead before the migration.
- **Caprasimo is bundled but unused.** The design ships the "Clean Sans" heading
  preset (Figtree bold). The Caprasimo `@font-face` rules and font files are still
  in place, so switching presets is a two-line change. If you commit to Clean Sans
  permanently, delete `src/assets/fonts/caprasimo-*.woff2` and their `@font-face`
  blocks to drop ~23KB.

## History

Earlier iterations of this site — a single HTML file with a client-side template
runtime — are on the `initial` branch. The move to Astro dropped 134KB of
runtime JavaScript, turned four hash-routed sections into real pages with their
own titles and meta tags, and moved blog content out of a JavaScript array into
markdown files.
