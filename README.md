# seanteare-portfolio

Personal portfolio and blog for Sean Teare. Built with [Astro](https://astro.build) —
static output, zero JavaScript shipped to the browser.

## Quick start

```bash
nvm use          # Node version is pinned in .nvmrc
npm install
npm run dev      # http://localhost:4321
```

| Command | Does |
|---|---|
| `npm run dev` | Dev server with hot reload |
| `npm run build` | Static build into `dist/` |
| `npm run preview` | Serve `dist/` exactly as it will deploy |
| `npm run check` | Type-check `.astro` and `.ts` files |

Astro needs Node 18.20+, 20.3+, or 22+. `.nvmrc` pins the major version, and CI
reads the same file via `node-version-file`, so the two cannot land on different
majors. They can still differ within 24.x — `nvm use` takes the newest version
installed locally, CI takes the newest released. Pin the full version in
`.nvmrc` if that ever matters.

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

Pushing to `main` triggers `.github/workflows/deploy-aws.yml`, which builds the
site, syncs `dist/` to S3, and invalidates CloudFront. It runs unattended —
publishing is idempotent and the bucket is versioned. Infrastructure changes are
the ones that wait for a human, and they go through `terraform.yml` and a
different environment. The same workflow can be run from the Actions tab to
redeploy without a commit.

`main` is protected: changes arrive by pull request, not direct push. Every pull
request builds and type-checks the site via `.github/workflows/site.yml`, so a
dependency bump that fails to install shows up before merge rather than as a
broken deploy.

Infrastructure — bucket, distribution, certificate, DNS, and the OIDC roles CI
assumes — lives in [`terraform/`](./terraform/README.md).

Two sync passes run, because the right cache header differs by file type: Astro
fingerprints everything under `_astro/`, so those are immutable and cached for a
year, while HTML keeps its URL across deploys and must revalidate.

`public/.nojekyll` is a leftover from GitHub Pages and no longer load-bearing.

## Known gaps

- **Keep the résumé PDF public-safe.** The Download button serves
  `public/Sean-Teare-Resume.pdf` verbatim. Replacing that file updates the
  download with no code change — but it is committed to a public repo, so scrub
  the phone number and home address from any version you drop in. The current
  file lists email, LinkedIn, and GitHub only.
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
