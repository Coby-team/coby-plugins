#!/bin/bash
# SessionStart hook — orient Claude Code on the Coby brain plugin and Fimo
# customer-intelligence patterns. Output goes into the session as additional
# context (not visible to the user).

cat <<'EOF'
Coby brain plugin is active. You have customer intelligence for Fimo
(Aurélien's product where customers create projects and write prompts).

Available MCPs:
- mcp__coby-brain__* — Fimo-internal data + identity-resolution. Holds: prompt
  content (full text + attachments), login history, project lifecycle, onboarding
  tour completions, per-entity timeline. Maps Fimo users to external IDs:
  posthog_distinct_id, pylon_contact_id. Read-only. (Hyperline mapping not wired.)
- mcp__posthog__* — product analytics (sessions, events, feature flags, errors).
- mcp__pylon__* — customer support (tickets, accounts, conversation history).
- mcp__hyperline__* — billing (subscriptions, invoices, financial state).

Always:
1. Brain-first for any customer question. Use mcp__coby-brain__search or query
   to resolve a Fimo entity (by name, email, ID) to a slug (user/<id>, org/<id>,
   project/<id>, prompt/<id>) before querying any vendor MCP.
2. Use mcp__coby-brain__get_timeline for Fimo-side activity (logins, prompts,
   projects, tours). Vendor MCPs only for what they uniquely hold (PostHog
   events outside Fimo, Pylon tickets, Hyperline invoices).
3. Cite slugs in answers (e.g. "Aurélien (`user/abc-123`)") for copy-paste.
4. If the brain returns nothing, say so — never fabricate IDs, emails, activity.
EOF
