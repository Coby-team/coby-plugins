---
name: customer-profile
description: Build a complete picture of a single Fimo customer — who they are, how they use the product, whether they pay, whether they hit bugs. Use whenever the user asks about a specific Fimo user by name, email, ID or company, or says things like "tell me about X", "who is X", "is X a customer", "what does X pay", "any issues with X", "is X churning", "what has X built", "should we worry about X". Composes the coby-brain MCP (identity + Fimo-side activity + PostHog usage + Pylon support) with the Hyperline MCP (billing). Read-only.
---

# Customer Profile

A customer profile answers "what's the full picture on this user?" — a question no single source can answer alone. The brain knows who they are inside Fimo. The downstream tools hold the live signals about how they behave, what they pay, and what they complain about.

## What each source uniquely holds

**coby-brain** — the canonical record and the proxy for PostHog + Pylon. For any Fimo user it returns the slug (`user/<id>`), email, primary org, the join keys for downstream queries, and Fimo-internal activity: logins, prompts (full text + attachments), projects created and published, tours completed. The prompts the user actually sent live here — content, not just counts. The brain also exposes `mcp__coby-brain__posthog_*` and `mcp__coby-brain__pylon_*` tools that hit those vendors' APIs server-side using Coby-managed tokens.

**PostHog** (via `mcp__coby-brain__posthog_*`) — what they do in the product. Sessions, events, errors, feature usage. Joined via `posthog_distinct_id` returned by the brain. The signal is *behavior*: are they active, where do they spend time, where do they get stuck.

**Pylon** (via `mcp__coby-brain__pylon_*`) — what they complain about. Tickets, conversations, themes. Joined via `pylon_contact_id` returned by the brain. The signal is *friction*: bugs they hit, requests they made, sentiment over time.

**Hyperline** (via the standalone `mcp__hyperline__*` MCP) — whether they pay and how much. Subscriptions, plan, MRR, invoices, status. Joined at the **org level** via the org's `hyperline_customer_id` — a user's billing lives on their `primary_org`. The signal is *commercial weight*.

## The one rule that matters

Resolve through `mcp__coby-brain__search` (or `query` for natural language) before touching any vendor tool. The brain returns the join keys directly (`posthog_distinct_id`, `pylon_contact_id`, and `hyperline_customer_id` on the user's primary org) — use what the brain returns rather than reconstructing keys from the email or Fimo ID yourself. The brain is the source of truth for the mapping; that's its whole job.

## What makes a profile useful

A good profile says who this person is in Fimo, how they use the product, what they pay, what they've complained about — and, when the data shows it, what those things say together.

The cross-source links are where the insight lives. A few illustrations of what's worth surfacing when the data supports it:

- PostHog shows they hit an error → Pylon has a ticket about it → confirmed bug on this customer.
- Brain shows their prompts were about feature X → PostHog shows they used X heavily then stopped → churn signal on a feature they cared about.
- Hyperline shows enterprise plan → Pylon shows 3 open tickets → priority customer with unresolved friction.
- Brain shows `last_login` 45 days ago → Hyperline shows still-active subscription → silent churn risk.

These are illustrations, not a checklist. Read the actual data and say what it actually shows.

## Output

Default: a markdown one-pager. Adapt to what the data supports — don't render empty sections, don't pad.

Cite the source for every fact so the user can audit:

- `Aurélien (user/abc-123)` — brain slug
- `Last session: 2026-04-30 (posthog: alex@strapi.io)` — vendor source + key used
- `Open ticket: "API rate limit" (pylon: #4421)` — clickable identifier
- `Plan: Pro $99/mo, paid through 2026-05 (hyperline: cus_xyz)` — commercial fact + key

Make gaps explicit. "No Pylon tickets in the last 90 days" is information. "Pylon unavailable" (upstream API error) is information too — note it, continue with the other sources.

## Don't

- Don't query a vendor tool without first resolving via the brain. Use the join keys the brain returns rather than guessing them from email or Fimo ID.
- Don't fabricate ticket numbers, session IDs, invoice IDs, plan names, or amounts. If a tool returned nothing, say so.
- Don't stop on the first vendor failure. Continue with the others and mark the gap.
- Don't treat the brain as the source of truth for vendor data — its PostHog and Pylon tools are a passthrough, not a warehouse. Live data lives in PostHog / Pylon / Hyperline.
