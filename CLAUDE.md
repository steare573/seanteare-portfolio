# CLAUDE.md

Guidance for Claude Code when working in this repo.

## Commits

**Never add a `Co-Authored-By: Claude` trailer to commit messages.** No
"Generated with Claude Code" footers either. Commit messages should read as if
written by the repo owner.

Write the message body to explain *why*, not to list files — the diff already
shows what changed.

## What this is

Sean Teare's personal portfolio and blog. Astro, static output, no JavaScript
shipped to the browser. Deployed to S3 + CloudFront (`seanteare.com`) via
`.github/workflows/deploy-aws.yml` on push to `main`.

## Commands

Node is not on the default PATH — it is installed via nvm, and the version is
pinned in `.nvmrc`. Prefix any command that runs node:

```bash
source "$HOME/.nvm/nvm.sh" && nvm use
```

```bash
npm run dev        # http://localhost:4321
npm run build      # static build to dist/
npm run preview    # serve dist/ exactly as it deploys
npm run check      # astro check — run before committing
```

Always run `npm run build` and `npm run check` before committing. Both are fast.

## Architecture

- `src/pages/` — file-based routing, one file per URL
- `src/content/blog/*.md` — blog posts; filename is the slug. Adding a file is
  the entire "add a post" workflow.
- `src/content.config.ts` — Zod frontmatter schema. Bad frontmatter fails the
  build by design; don't loosen the schema to make an error go away.
- `src/data/resume.ts` — skills, stats, job history, profile text. Shared by the
  home and résumé pages.
- `src/styles/design-system.css` — tokens and component classes. This is the
  source of truth for the visual system; prefer retuning tokens over adding
  one-off CSS.

## Gotchas

These each cost a debugging cycle already. Don't rediscover them.

- **Base path.** The site deploys to a Pages *project* URL, so every internal
  link needs the `base` prefix. Use `path()` from `src/lib/paths.ts` — never
  hardcode a leading-slash href.
- **`<Image>` and `aspect-ratio`.** Astro emits explicit `width`/`height`
  attributes, and `aspect-ratio` is ignored unless a dimension is `auto`. Always
  pair `aspect-ratio` with `height: auto`.
- **`.prose` specificity.** In `site.css`, `.prose > *` (reset) must come before
  `.prose > * + *` (spacing). Using `.prose p` for the reset outranks the sibling
  selector and silently collapses paragraph spacing.
- **Astro frontmatter.** A multi-line `export type X = | 'a' | 'b'` union in a
  component's frontmatter fails to parse. Use `keyof typeof` off a const object.
- **`public/.nojekyll` is inert now.** It mattered on GitHub Pages, where Jekyll
  stripped the underscore-prefixed `_astro/` paths Astro emits. S3 does not care.
  Harmless to keep, harmless to delete.

## Style

Match the surrounding code. Inline `style` attributes are used heavily in the
page templates — that came from the original design export and is intentional
for one-off layout; shared visual language belongs in `design-system.css`.
