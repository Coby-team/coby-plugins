#!/bin/bash
# SessionStart hook — orient Claude Code on the Coby brain plugin and Fimo
# customer-intelligence patterns. Output goes into the session as additional
# context (not visible to the user).

cat <<'EOF'
Coby brain plugin is active. You have customer intelligence for Fimo
(Aurélien's product where customers create projects and write prompts).

Available MCPs:
- mcp__coby-brain__* — the Coby brain. Four groupings under one namespace:
    * Brain-native (identity + Fimo-internal data): prompt content (full text
      + attachments), login history, project lifecycle, onboarding tour
      completions, per-entity timeline. Maps Fimo users to external IDs
      (posthog_distinct_id, pylon_contact_id; hyperline_customer_id = fimo_org_id
      on each org). Read-only. Tools include search, query, get_page,
      get_timeline, get_chunks, traverse_graph, list_pages, resolve_slugs,
      get_prompt_attachment, get_integration_guide.
    * mcp__coby-brain__posthog_* — curated PostHog product analytics
      (sessions, events, feature flags, errors, HogQL via posthog_query).
    * mcp__coby-brain__pylon_* — curated Pylon customer support
      (tickets, accounts, contacts, messages, organization).
    * mcp__coby-brain__hyperline_* — curated Hyperline billing
      (customer, subscriptions, invoices, valuation, payment methods, credits,
      portal URL, analytics). Read-only.

Always:
1. Brain-first for any customer question. Use mcp__coby-brain__search or query
   to resolve a Fimo entity (by name, email, ID) to a slug (user/<id>, org/<id>,
   project/<id>, prompt/<id>) before drilling into product / support / billing.
2. Use mcp__coby-brain__get_timeline for Fimo-side activity (logins, prompts,
   projects, tours). PostHog (mcp__coby-brain__posthog_*), Pylon
   (mcp__coby-brain__pylon_*), and Hyperline (mcp__coby-brain__hyperline_*)
   for what they uniquely hold.
3. Cite slugs in answers (e.g. "Aurélien (`user/abc-123`)") for copy-paste.
4. If the brain returns nothing, say so — never fabricate IDs, emails, activity.

Recovery — if brain tools are unavailable or auth-failing:
If you discover that `mcp__coby-brain__*` tools are missing from this
session, OR if any brain call returns an authentication error, do NOT
try to answer customer questions from general knowledge. Instead:

  1. Tell the user clearly: "Your Coby brain credential looks missing
     or invalid (this can happen after a Claude Code self-upgrade).
     Run `npx @joincoby/cli doctor` in a terminal to diagnose and
     repair, then `/reload-plugins` here to reconnect."

  2. Optionally, you may proactively run `npx @joincoby/cli doctor
     --diagnose-only` via the Bash tool first to confirm the diagnosis
     before asking the user to repair. This command is non-interactive,
     prints a human-readable status, and exits 0 if everything is fine
     (so you can skip the user-facing message in that case).

  3. Never fabricate customer data to compensate for a broken brain.
EOF
