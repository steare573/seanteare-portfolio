---
title: "What I Learned Leading Teams Through Legacy Rewrites"
excerpt: "On taking over a mobile-pay backend that was missing its SLOs, and the shared-services platform that came after it."
tag: "Engineering Leadership"
date: 2023-11-01
readTime: "5 min read"
draft: true
---

Inheriting a system that's already missing its SLOs is a specific kind of leadership problem. The team isn't lacking effort; they're usually exhausted from firefighting a design that can't hold the load it's being asked to carry. The first job isn't to write code — it's to give the team permission to stop patching and start rebuilding.

The rewrite of Passport's mobile-pay parking backend taught me to separate the promise from the plan: commit to the SLA the business needs, but hold the implementation plan loosely enough to change when the first two approaches don't scale. We got there, but not on the first try.

What came after mattered as much as the rewrite itself. Turning the lessons into a shared-services platform — user management, authorization, geospatial handling, PCI payments — meant the next team with a scaling problem didn't have to relearn it from scratch. That's the real output of a hard rewrite: not just a system that works, but a foundation the next five projects can stand on.
