---
title: "Scaling an OAuth Platform to 60,000 Concurrent Requests"
excerpt: "Notes from rebuilding the authentication tier behind every Ally customer-facing and server-to-server API, and cutting p95 latency 5x in the process."
tag: "Platform Engineering"
date: 2025-03-01
readTime: "5 min read"
---

Every request to every Ally API — consumer-facing or server-to-server — passes through a token issued by a small set of OAuth provider servers. At that scale, a token service isn't a utility; it's load-bearing infrastructure, and it has to behave predictably at 60,000 concurrent requests without anyone noticing it exists.

The previous implementation worked, but latency crept upward under peak load in ways that were hard to diagnose after the fact. Rather than patch the symptom, we re-architected the minting and validation paths from the ground up, rethinking caching boundaries and where synchronous work could become asynchronous without weakening the security model.

The result was a 5x improvement in p95 latency — not from one clever trick, but from refusing to accept that a five-year-old architecture had to be the ceiling. Platform work rarely gets a demo day. The payoff shows up as an incident that never happens.
