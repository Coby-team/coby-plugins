---
name: coby-brain-lookup
description: Use whenever the user asks about a Fimo user, organization, project, or prompt — by ID, email, slug, or natural language. Routes to the coby-brain MCP (search, query, get_page, get_timeline, get_links, get_backlinks) instead of guessing from training data. Trigger on names / IDs / emails of Fimo entities and on questions like "who built X", "what did user Y do recently", "members of org Z", "find users using feature W".
---

# coby-brain lookup

The Coby brain is the source of truth for Fimo identity-resolution data. It holds canonical pages for users, orgs, projects, and prompts, plus the link graph between them and a per-page timeline. Always query the brain instead of guessing from training data.

## Pick the right entry tool

- **Exact identifier known** (UUID, email, slug like `user/abc`) → `mcp__coby-brain__search` with that exact string. Best for IDs, emails, exact phrases.
- **Natural-language question** ("users building CRMs", "Aurélien's recent prompts") → `mcp__coby-brain__query` for hybrid retrieval (FTS + embeddings).
- **Listing entities of a type** ("all orgs", "users created this week") → `mcp__coby-brain__list_pages` with a `type` filter and `updated_after` if recency matters.
- **Slug already known** → `mcp__coby-brain__get_page` directly. Set `fuzzy: true` if the exact slug might be slightly off.

## Then enrich

Once you have a slug:
- Recent activity → `mcp__coby-brain__get_timeline` (logins, prompts sent, projects created, tour events)
- Outgoing relations (orgs a user belongs to, project's owner) → `mcp__coby-brain__get_links`
- Incoming relations (members of an org, prompts authored by a user, projects in an org) → `mcp__coby-brain__get_backlinks` with a `link_type` filter
- Multi-hop exploration ("who collaborates with X across orgs") → `mcp__coby-brain__traverse_graph`
- Debugging a missing or unexpected field → `mcp__coby-brain__get_raw_data` to see source rows

## Slug patterns

- `user/<fimo_user_id>` — better-auth user UUID
- `org/<fimo_org_id>` — better-auth org UUID
- `project/<uuid>`
- `prompt/<uuid>`

## Known link types

`authored_by` (prompt → user), `created_by` (project → user), `belongs_to` (project → org), `member_of` (user → org), `in_project` (prompt → project).

## Iron rules

- Never paraphrase or fabricate identity data from training. If the brain returns nothing, say so plainly — do not invent IDs, emails, org names, or activity.
- Never embed a Fimo ID/email in your answer without first looking it up. If the user gives you an unknown ID, verify it before reasoning on it.
- Cite the slug when reporting facts about an entity, so the user can audit (e.g. "Aurélien (`user/abc-123`) belongs to ...").
- Read-only: there is no write tool. If the user asks to update something, tell them this MCP is read-only and the source DB is the only place to change it.
