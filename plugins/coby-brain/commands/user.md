---
description: Look up a Fimo user by ID, email, or slug, and return a compact profile (orgs, recent activity, projects, prompts).
---

Look up the Fimo user described by: $ARGUMENTS

## 1. Resolve the user

Pick the cheapest tool based on what `$ARGUMENTS` looks like:

- **Already a slug** (`user/<uuid>`) → `mcp__coby-brain__get_page` directly. If it 404s, retry with `fuzzy: true`.
- **Looks like a UUID** (no `user/` prefix) → try `mcp__coby-brain__get_page` with `slug: "user/<uuid>"`.
- **Looks like an email** or **a name fragment** → `mcp__coby-brain__search` first. Then `get_page` on the top hit.
- **Ambiguous — multiple plausible search hits** → list the top 3-5 hits and ask the user which one they mean. Do NOT silently pick the first.
- **Nothing matches** → say so plainly. Suggest `/coby-brain:status` if you suspect a connection issue.

## 2. Enrich (run these in parallel once you have a slug)

- `mcp__coby-brain__get_links` with `slug: "user/<id>"`, `link_type: "member_of"` — orgs they belong to
- `mcp__coby-brain__get_backlinks` with `slug: "user/<id>"`, `link_type: "authored_by"`, `limit: 10` — prompts they wrote
- `mcp__coby-brain__get_backlinks` with `slug: "user/<id>"`, `link_type: "created_by"`, `limit: 10` — projects they created
- `mcp__coby-brain__get_timeline` with `slug: "user/<id>"`, `limit: 20` — recent activity (logins, prompts, projects, tour events)

If any of those return more than `limit`, say "(showing <limit> of <total>)" so the user knows there's more.

## 3. Render

Output format:

```
<title-from-page> — `user/<id>`

Identifiers
  email           <from compiled_truth>
  fimo_user_id    <id>
  <any other ids surfaced in compiled_truth>

Orgs (<N>)
  - <org-title> (`org/<id>`) — role: <role>
  - ...

Recent activity (last <N>)
  <ISO date> — <event description>
  ...

Projects (<N total>, showing 3 most recent)
  - <project title> (`project/<id>`) — created <date>

Prompts (<N total>, showing 3 most recent)
  - <prompt title> (`prompt/<id>`) — <date>
```

Keep it dense — one screen if possible, no decorative fluff. Always include slugs in backticks so the user can copy-paste them into follow-up commands.
