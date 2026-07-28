import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
// Re-exported from 'astro:content' until Astro 7 deprecated it. Same zod,
// different entry point.
import { z } from 'astro/zod';

// Blog posts are plain markdown in src/content/blog/. Add a file, get a page —
// the index and the post route both build themselves from this collection.
// Frontmatter is validated at build time, so a typo fails the build instead of
// rendering an empty slot.
const blog = defineCollection({
  loader: glob({ base: './src/content/blog', pattern: '**/*.md' }),
  schema: z.object({
    title: z.string(),
    excerpt: z.string(),
    tag: z.string(),
    /** Publish date. Drives ordering and the displayed "Month YYYY". */
    date: z.coerce.date(),
    readTime: z.string(),
    /** Set true to keep a post out of production builds. */
    draft: z.boolean().default(false),
  }),
});

export const collections = { blog };
