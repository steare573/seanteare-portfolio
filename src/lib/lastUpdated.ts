/**
 * Per-post "last updated" timestamps, read out of git history.
 *
 * The value has to be per-post: a deploy that changes one post must not
 * restamp the other three. That rules out the two obvious sources. A build
 * timestamp is one value for the whole run, and so is the deploy time — using
 * either directly would move every post's date on every deploy, which is the
 * one behaviour this must not have. Making a literal deploy timestamp behave
 * per-post would mean carrying a manifest between deploys and reading it back
 * at build time, i.e. a stateful build whose output differs from a local one.
 *
 * Git already records which commit changed which file, so take it from there:
 * the committer date of the most recent commit touching the post. `main`
 * receives work through merges from `develop`, so `--first-parent` with
 * `--diff-merges=first-parent` attributes a file to the merge that landed it on
 * main rather than to the older branch-side commit — and that merge is the push
 * that fires deploy-aws.yml. The result sits one workflow run behind the real
 * deploy, and needs no state to compute.
 *
 * Node-only: this shells out to git during SSG. It must never reach browser
 * code, which is free today because the site ships no client JS.
 */

import { execFileSync } from 'node:child_process';
import { statSync } from 'node:fs';

/** Loader base from src/content.config.ts, relative to the repo root. */
const BLOG_DIR = 'src/content/blog';

/** Run git, or return null if it fails — a missing repo is a fallback, not a build break. */
function git(args: string[]): string | null {
  try {
    return execFileSync('git', args, {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    });
  } catch {
    return null;
  }
}

/**
 * A shallow clone can only see the tip commit, so every post would report the
 * same date and the page would look fine while being wrong. Say so loudly —
 * this is what `fetch-depth: 0` in deploy-aws.yml exists to prevent.
 */
function warnIfShallow(): void {
  if (git(['rev-parse', '--is-shallow-repository'])?.trim() === 'true') {
    console.warn(
      '[last-updated] Shallow clone detected: git history is truncated, so every ' +
        'post will report the same commit date. Set `fetch-depth: 0` on actions/checkout.'
    );
  }
}

/** Repo-relative post path -> ISO 8601 committer date. Built once per build. */
let commitDates: Map<string, string> | null = null;

function loadCommitDates(): Map<string, string> {
  if (commitDates) return commitDates;

  const dates = new Map<string, string>();
  warnIfShallow();

  // One call for every post. %x00 prefixes each commit with a NUL, which
  // filenames cannot contain, so the date line is unambiguous to split on.
  const log = git([
    'log',
    '--first-parent',
    '--diff-merges=first-parent',
    '--format=%x00%cI',
    '--name-only',
    '--',
    BLOG_DIR,
  ]);

  if (log) {
    // Commits arrive newest-first, so the first sighting of a path is its most
    // recent change and every later sighting is older history.
    for (const commit of log.split('\0')) {
      const [iso, ...files] = commit.split('\n');
      if (!iso) continue;
      for (const file of files) {
        const p = file.trim();
        if (p && !dates.has(p)) dates.set(p, iso);
      }
    }
  }

  commitDates = dates;
  return dates;
}

/** When this post's file last changed. */
export function lastUpdated(entry: { id: string; filePath?: string }): Date {
  const rel = (entry.filePath ?? `${BLOG_DIR}/${entry.id}.md`).replaceAll('\\', '/');

  const iso = loadCommitDates().get(rel);
  if (iso) return new Date(iso);

  // A post that is written but not yet committed has no history to read. Its
  // mtime is the honest answer and keeps `npm run dev` useful while drafting.
  try {
    return statSync(rel).mtime;
  } catch {
    return new Date();
  }
}

// Constructed once — Intl formatters are expensive enough to be worth hoisting,
// and this one is identical for every post.
const EASTERN = new Intl.DateTimeFormat('en-US', {
  month: 'long',
  day: 'numeric',
  year: 'numeric',
  hour: 'numeric',
  minute: '2-digit',
  timeZone: 'America/New_York',
  timeZoneName: 'short',
});

/**
 * "July 28, 2026 at 6:45 PM EDT".
 *
 * Named zone rather than a fixed -05:00/-04:00, so the EST/EDT switch is
 * handled for us and a post stamped in January reads correctly in July.
 */
export function easternTimestamp(date: Date): string {
  return EASTERN.format(date);
}
