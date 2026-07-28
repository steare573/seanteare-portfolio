---
title: "Four Months to an AI-Native Practice That Worked"
excerpt: "Five years inside a Fortune 100 company where AI never got past autocomplete, then four months building an agent-driven practice that genuinely delivered — and the two problems left over that engineering couldn't solve on its own."
tag: "AI-Native Engineering"
date: 2026-07-28
readTime: "8 min read"
---

I spent most of fifteen years doing enterprise-shaped engineering, the last five of them inside a Fortune 100 company. Then I spent four months at a startup where every piece of work moved through an agent. The four months rearranged more of my practice than the five years did.

Four months is short enough that you should be suspicious of anyone drawing conclusions from it, so let me argue that the compression is itself the finding, not a caveat on it. Approaches that would have taken a year to evaluate under enterprise change control got evaluated in a week, which is the only reason a practice could converge that fast.

Here's where I landed, up front. With a real specification feeding it, a verification loop behind it, and genuine integration into the tools the team already works in, this works — and it produced the largest change in delivery throughput I've seen in fifteen years, by a margin that isn't close. We got there. The engineering workflow ended up in good shape, and most of this post is how.

What we didn't solve were two problems that turned out not to be engineering problems at all. Both of them live at the boundary between engineering and everyone else, now that everyone else can generate code too. I'll come back to them at the end, because I think they're where the interesting work is next.

## Starting from two extremes

Inside the enterprise, we were using AI. That sentence was true, it was reported upward as a success, and it produced very little.

The model was internal-only and a generation or two behind the frontier, because sending proprietary code to a third party required a review that outlasted the reason for wanting the tool. The approved list wasn't refreshed on a cadence so much as refreshed eventually, always well behind where the industry had already moved. Scope was capped at assistant and never allowed to become agent: autocomplete and chat were fine, but anything that could write a file, run a command, or open a pull request unattended couldn't be squared with a change control regime where every change traces to a named human. And whatever the model produced was still subject to the same complete human review as before.

That last constraint is the one that decided the outcome. The review load never moved, so the throughput never moved. We had a program that was fully auditable and nearly useless, and the two properties were related.

The startup had none of those constraints, and the difference was immediate. Work that would have been a quarter in the enterprise was a week. Ideas that would never have cleared the cost of trying them got tried and kept. I don't want that buried under what follows, because it's the reason any of the rest is worth working on.

The early failures were the mirror image of the enterprise's. Under deadline pressure the specification step quietly became optional, and the change that skipped it was never as small as it sounded, because an agent wrote it. Code merged that no human had read end to end. When an agent reported that the tests passed and there were no side effects, we sometimes believed the report instead of checking it.

Those were learning-curve problems and we fixed them, which is the part I'd want an enterprise reader to take seriously. None of them required restricting what the model was allowed to do. They required building the structure that should have been around it in the first place.

I don't think either extreme is really a story about the amount of AI. The enterprise restricted the model heavily; the startup started out not restricting it at all. Both were adjusting the same dial. But how much you let a model generate isn't the variable that determines whether the output is safe. What determines that is how much structure sits on either side of the generation step — specification going in, verification coming out — and whether that structure was built for one person or for a team.

## Learning the tools by using them

I learned the tooling by running real work through it, not by reading about it. There's no substitute for that; the useful knowledge is all in where things fail, and the failures aren't documented because they're specific to your repository, your conventions, and your team.

The first real choice was between an IDE-embedded assistant and a terminal-native agent, and Cursor lost to Claude Code on a distinction that turned out to be the whole game. An embedded assistant optimizes for a human typing with help. We needed something that could run the full loop unattended — read the spec, write the code, run the tests, open the pull request — with the human at the ends rather than in the middle. That's a different tool, not a better one.

Then everything moved. Model upgrades changed what an agent could hold in context, which meant re-tuning specifications that had been written around a smaller window. We pulled our prompting patterns into a centralized set of company-specific skills with defined agent roles, so that the accumulated knowledge lived in the repository instead of in whoever had figured it out. We ran more multi-agent workflows and fewer single-threaded ones. We consolidated on OpenSpec after trying other specification frameworks, centralized the product and technical documents that fed it, and pulled the resulting tickets into Linear so task management stopped being a parallel universe.

Almost every specific tool decision I made in April had been revised by July. The specification layer and the verification layer survived all of it. That's the argument for putting your investment there: the layers are what persist while the things implementing them get replaced underneath you.

## Start where you can check the answer

Learning to ask the AI first was a reflex problem, not a belief problem. I already believed it was faster. My hands still reached for grep, for the docs, for a teammate — and it took a while to recognize that the old reflex was itself a skill, built deliberately over fifteen years, and that unlearning it would feel like getting worse at my job whether or not I actually was.

The place that reflex actually changed was debugging, and I'd now recommend debugging as the on-ramp for anyone skeptical. Greenfield generation asks you to trust output you have no independent way to evaluate. Debugging doesn't: the bug either reproduces or it doesn't, the fix either holds or it doesn't. The answer is checkable and the loop is cheap, which makes it the right place to calibrate before extending trust anywhere it costs more to be wrong.

With access to logs, traces, and metrics alongside the codebase, triage was almost always faster than I would have been. The one that convinced me was an address bug — we'd started storing records with the unit numbers missing, and the cause was a third-party webhook integration that had quietly changed its format after a bad upload on their side. That's a needle that lives at the seam between someone else's data and our parsing, and finding it means correlating production records against integration code. It's exactly the kind of unglamorous correlation work that a human does slowly and an agent with the right access does immediately.

## The chain from an idea to merged code

For a large project, the chain started before any ticket existed: architecture and coding standards committed to the repositories, so there was a fixed definition of correct that every agent read.

Product wrote the PRD in Notion. An agent analyzed it and posted clarifying questions back into the document, so the ambiguities surfaced in writing, in product's own tool, before anyone built against a guess. From the answered PRD we generated a TRD and committed it to the repository being worked on — and that seam, product documents in Notion and technical documents in version control, mattered more than it sounds. The moment the technical shape lives in the repo, it's reviewable, diffable, and available to every agent working in that codebase without anyone pasting context.

OpenSpec change proposals came off the TRD, with assignees and dependencies mapped. From there each ticket ran the same path: implementation via TDD, a pull request, review by a separate adversarial agent — one that hadn't written the code, and that argued from the specification and the repo standards instead of defending the implementation — fixes applied by the implementing agent, and a human approving at the end.

The adversarial reviewer is the piece I'd bring to any team first. I expected confident, plausible, worthless comments — the failure mode that makes people start rubber-stamping — and got the opposite. It found real defects, not style noise, argued them from the specification, and the fix-and-repush loop closed without a human in it. A reviewer that never gets tired, never gets social about it, and has actually read the standards document is a better reviewer than most teams have access to.

That's the shape of the whole thing when it works: the specification is unambiguous, the feedback loop is tight and automatic, and the agent has first-class access to the same systems the team does. Get those three right and the throughput is genuinely hard to believe.

The collaboration half of this is what I'd underestimated. Three to five engineers, all running agents. Ticket assignment came from commit history and from how much work there was to divide — preference to whoever knew the code, short of overloading them — and the subject matter expert stayed the final decision maker on the applications they mainly worked in. The discipline that made it hold was that when someone discovered the TRD was wrong, the TRD got amended and committed before work resumed. That sounds bureaucratic until you picture the alternative: one engineer proceeds from a corrected understanding while everyone else's agents continue from the stale document, quietly and very quickly. When the workflow was followed, integration went smoothly, and engineers who finished early could swarm onto work from engineers who hadn't.

## The seams are the last hard part

At some point you accept that no one is going to read all of it. That acceptance is correct, and it's only safe if you replace reading with something. The honest version is that you move the control from reading to verification. The dishonest version is that you stop reading and replace it with nothing.

We moved the control, and it held. Where it didn't hold is specific enough to be worth naming precisely, because it's the one structural gap I'd warn any team about in advance.

Our tests inherited the shape of our ticket decomposition. Work was split by ticket, so each agent wrote tests scoped to its ticket. Every slice got verified against its own specification, and nothing verified the boundaries between slices. The TDD tests passed without accounting for work other people were doing concurrently. The integration tests covered scenarios specific to the ticket that produced them, not the requirements that lived in adjacent tickets. And the adversarial reviewer, as good as it was, reviews a pull request — so it inherited exactly the same tunnel vision.

Every automated gate we had was ticket-shaped or PR-shaped. Each one worked well at the scope it was given, and none of them had a whole-system view, so defects that lived between tickets could pass through all of them.

The fix isn't complicated, which is the encouraging part: an integration test audit — someone stepping back to write and tune tests against whole business flows rather than individual tickets. The reason it doesn't happen on its own is the reason it's worth saying out loud — it isn't anybody's ticket. If you parallelize implementation across agents, verification of the seams stays stubbornly human for now, and it has to be made someone's explicit job.

That's a scheduling decision, not a limitation of the tooling, and it's the one thing I'd set up differently from day one rather than discovering it at integration.

## The two problems that weren't engineering problems

The engineering workflow got where it needed to be. The two things we didn't resolve both sat at the boundary between engineering and the rest of the business, and I don't think either is unique to us.

The first was expectations. Leadership anchored on demos — theirs and the industry's — and the number they took away from watching a working slice appear in an hour became the number in the commitment.

What they'd watched was implementation, which is the one phase AI genuinely collapses. The phases compress unevenly. Implementation falls through the floor. Specification compresses some, but the clarifying questions still need a human product answer and that answer arrives on human time. Seam verification barely compresses at all. So the more implementation collapses, the larger the share of the schedule the incompressible work becomes — and a team quoting on implementation speed is quoting on the fraction that's disappearing.

The speed is real — that's what makes this hard rather than simple. If the demo were misleading, you'd just explain that. It isn't. Implementation really does collapse the way it appears to, and the honest correction is narrow and unsatisfying: the part you watched got faster, and the parts you didn't watch mostly didn't.

We never fully closed that gap in four months. What it cost us was the room to validate as thoroughly as we went, and it caused friction. I'd rather say that plainly than pretend the estimation conversation was solved.

The second was that people outside engineering could now build things that run. Prototypes started arriving as real, working applications — built by people who reasonably concluded that running meant nearly finished. They came without the shared data layer, each one owning its own database, and engineering inherited the reconciliation: pipelines to sync prototype data with what the production system actually ran on.

I want to be careful here, because the instinct to read that as a complaint is exactly wrong. Those prototypes were genuinely useful. They communicated intent better than any document, and the people building them were doing something I'd want them to keep doing. What was missing was a shared understanding of what a prototype is for. A prototype that proves the idea is enormously valuable. The same prototype treated as a head start on production is a bill that arrives later, in integration.

That's a solvable problem, and it's an organizational one rather than a technical one. Nobody had drawn the line yet, because until recently there was no line to draw — non-engineers couldn't produce running software at all. We were early enough that the norm simply didn't exist yet.

## What I'd tell someone starting

The dial everyone argues about isn't connected to anything. The enterprise turned it down and got a program that satisfied its auditors and moved no work. We started with it turned all the way up and got speed before we'd built anything to catch what the speed produced. Neither position was calibrating the thing that mattered.

What matters is the specification the work starts from, the verification it has to survive, and whether both were designed for a team rather than for one person with an agent. Get those three right and the volume stops being frightening — you're no longer trying to read your way to confidence, which was never going to scale anyway. And you can get them right quickly. That's the part I didn't expect. It took us four months, and most of that was discovering that the layers mattered more than the tools sitting in them.

So I'd say this to anyone still deciding: the capability is considerably further along than most enterprises have let themselves find out, and it is not fragile once the structure is around it. Build the specification layer, build the verification layer, make the seams somebody's explicit job, and have the conversation about what a prototype is for before you need it. That's a short list, and none of it is about how much AI to allow.
