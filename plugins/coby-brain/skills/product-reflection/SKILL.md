---
name: product-reflection
description: Force a PM to confront brain data while making a feature decision. Use whenever the user is weighing whether to build something — phrases like "should I build X", "is this the right feature to ship", "is X worth building", "should we prioritize X", "what should I build next", "feature decision", "prio backlog", "I'm thinking of building X", or explicit invocations like "use product reflection on X". Walks through 4 Shreyas Doshi forcing questions (JTBD, Type 1/2 decision, pre-mortem, LNO), pre-fetching brain data at each one and confronting the PM's hypothesis with what their own product actually shows. Output: a one-page decision summary in chat.
---

# Product Reflection

A product reflection answers "is this the right feature to build, given what my product data actually says?" — a question a PM cannot answer alone without switching tabs and losing the thread. The brain holds the data (PostHog usage, Pylon support themes, Fimo prompt content). The skill brings the data into the same flow as the decision and forces the PM to confront their hypothesis with reality before they commit.

This skill is the office-hours pattern (forcing questions, one-at-a-time AskUserQuestion, decision summary out) re-aimed from "is this the right startup" to "is this the right feature." It encodes Shreyas Doshi's PM thesis — JTBD, Type 1/2, pre-mortem, LNO — augmented by live data pulled from the brain at every question.

## The one rule that matters

**Prediction before data, every single question.** The PM declares their hypothesis on the dimension first. Then the skill pulls the data. Then the skill confronts. Reversing the order contaminates the prediction and kills the challenge — at that point the skill is just a fancier dashboard.

## What each brain weapon uniquely holds for product decisions

**`mcp__coby-brain__query`** (semantic) — what users actually wrote when trying to do similar things. Use for JTBD: search Fimo prompt content (scope `types: ['prompt']`) to surface the *language* users use about the job. Default `limit` is 10, max 50.

**`mcp__coby-brain__posthog_query`** (HogQL) — the volume and behavior signal. Use for LNO and pre-mortem failure modes. The feature area's distinct user count (last 30d) tells you whether you're touching a wedge or a backwater. The errors near affected paths tell you whether you've shipped this failure shape before. **10-second timeout** — every query bounded by date range and `LIMIT`.

**`mcp__coby-brain__pylon_search_issues`** — what users have already complained about in writing. Use for pre-mortem: search for past failure themes near the feature area, 90-day window, `limit: 50`. Different from `pylon_list_issues` which is capped at 30 days.

Hyperline (`mcp__coby-brain__hyperline_*`) is intentionally not called in V1 — there is no brain ↔ Hyperline cohort mapping yet. The LNO question uses PostHog volume as its signal. V2 adds MRR once the bridge lands.

## The flow

Three phases. Strict order. Stop after each AskUserQuestion and wait for the PM's response.

### Phase 1 — Frame

Ask the PM to state the feature idea in 1-2 sentences via AskUserQuestion. Echo back a one-sentence reformulation in your own words and ask them to confirm or correct. Catch mis-framings here, not at Phase 3.

No data pull yet. Just framing.

### Phase 2 — Four forcing questions

Ask each question via AskUserQuestion, one at a time, in order. **Never batch.** For each question, follow the same five-step shape:

1. State the Doshi frame in one sentence.
2. Ask the PM to declare their hypothesis on this dimension. **Wait for the answer.**
3. Pull the brain data using the tool listed in the table below, with the stated scope guardrails.
4. Confront the hypothesis with the data — name the gap explicitly. If hypothesis and data agree, say so plainly; agreement is also a signal.
5. Ask the PM to revise their position or defend it. Capture their final answer for Phase 3.

**The four questions (locked):**

| # | Doshi frame | What the PM declares | Brain tool + scope |
|---|---|---|---|
| 1 | **JTBD** — Who hires this feature, for what job? | Target persona + the job they want done, in their own words | `mcp__coby-brain__query` with `types: ['prompt']`, `limit: 20` — surfaces what users actually wrote when attempting the job |
| 2 | **Type 1 vs Type 2 decision** — Is this reversible or one-way? | Their read on reversibility + the cost of being wrong | None — pure framing question, no data pull. Confirms risk posture before pre-mortem. |
| 3 | **Pre-mortem** — Six months from now, this feature is a failure. Why? | Top 2-3 failure modes | `mcp__coby-brain__pylon_search_issues` for similar past failure themes (90d, `limit: 50`) **and** `mcp__coby-brain__posthog_query` HogQL on `events` table filtered to `$exception` events near the feature area |
| 4 | **LNO** — How leveraged is this against alternatives on the backlog? | Where it lands: Leveraged / Neutral / Overhead | `mcp__coby-brain__posthog_query` HogQL: `count(DISTINCT person_id)` over the feature area, last 30d, bounded by date range, 10s budget |

Notes on execution:

- **Cross-question caching.** If Q1's data pull already surfaced the cohort, Q4 can reference it instead of re-querying. Hold per-question results in working memory through the skill run.
- **Graceful degradation.** If a tool returns empty, errors, times out, or the source isn't connected, output: `Data unavailable for question N: <reason>. Continuing with hypothesis only — flag this as a known gap.` Then proceed.
- **Q1 escape hatch.** If the PM cannot name a persona ("I don't know who hires this"), offer to surface the top 5 Fimo cohorts by relevant event from PostHog so they can choose. This is the only adaptive branch in V1.
- **HogQL authoring.** You author the exact HogQL at runtime based on the feature area the PM described in Phase 1. Always `LIMIT` raw scans, always bound by date range. Run `posthog_query` once with EXPLAIN if you're unsure of the cost.

### Phase 3 — Decision summary

Render an in-chat markdown block with these sections, in this order. Cite source IDs for every fact so the PM can audit.

```
**Feature.** <PM's reformulated one-sentence framing from Phase 1>

**Final hypothesis (post-confrontation).**
- JTBD: <PM's revised answer to Q1>
- Type 1/2: <Q2>
- Pre-mortem: <Q3>
- LNO: <Q4>

**Gaps surfaced.**
- Q<N>: <one-line gap between initial hypothesis and what the data showed, or "agreed" if no gap>

**Validation step.**
<one concrete action the PM commits to before building — not "go build it" but something
testable. e.g. "ship a 3-line landing page to the top-20 PostHog cohort by Friday,
measure event signup_clicked over 7 days, come back to this summary and check the result
against the hypothesis.">

**Sources cited.**
- posthog_query: <query_id or HogQL excerpt>
- pylon: <issue_id list>
- coby-brain: <slugs touched>
```

No write to disk, no `put_page`, no brain write. The summary lives in the chat transcript. The PM copies what they want.

## What makes a reflection useful

A good product reflection is one where at least one question's data confrontation made the PM say "huh, I didn't see that coming." That's the moment the skill earned its run. If all four questions confirmed the PM's prior hypothesis without surprise, the skill still produced a clean decision summary — but the next reflection should reach for harder data (deeper HogQL, broader Pylon search, prompts beyond the obvious match).

The PM's reformulated hypothesis at the end matters more than the original. The whole point is the revision, not the first answer.

## Don't

- **Don't pull data before the PM declares their hypothesis** on a question. Order is load-bearing.
- **Don't batch questions.** One AskUserQuestion at a time. STOP and wait after each.
- **Don't fabricate query IDs, issue numbers, or counts.** If a tool returned nothing or errored, say so and move on.
- **Don't call Hyperline tools in V1.** The brain ↔ Hyperline mapping isn't wired yet. LNO uses PostHog volume.
- **Don't write the summary to disk or to the brain.** In-chat markdown only. The brain has no `put_page` for skill output.
- **Don't paginate large Pylon returns.** Bound by `limit: 50` and summarize themes, don't dump issues.
- **Don't loop or re-run mid-flow.** Linear pass. If the PM wants a second reflection on a different feature, they invoke the skill again.
- **Don't soften the confrontation.** Doshi-direct voice — name the gap plainly. Hedging defeats the forcing function.
