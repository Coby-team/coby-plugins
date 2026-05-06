#!/bin/bash
# SessionStart hook — orient Claude Code on the Coby brain plugin and Fimo
# customer-intelligence patterns. Output goes into the session as additional
# context (not visible to the user).

cat <<'EOF'
Coby brain plugin is active. You have customer intelligence for Fimo
(Aurélien's product where customers create projects and write prompts).

Available MCPs:
- mcp__coby-brain__* — the Coby brain. Three groupings under one namespace:
    * Brain-native (identity + Fimo-internal data): prompt content (full text
      + attachments), login history, project lifecycle, onboarding tour
      completions, per-entity timeline. Maps Fimo users to external IDs
      (posthog_distinct_id, pylon_contact_id). Read-only.
      (Hyperline mapping not wired.) Tools include search, query, get_page,
      get_timeline, get_chunks, traverse_graph, list_pages, resolve_slugs,
      get_prompt_attachment, get_integration_guide.
    * mcp__coby-brain__posthog_* — curated PostHog product analytics
      (sessions, events, feature flags, errors, HogQL via posthog_query).
    * mcp__coby-brain__pylon_* — curated Pylon customer support
      (tickets, accounts, contacts, messages, organization).
- mcp__hyperline__* — billing (subscriptions, invoices, financial state).

Always:
1. Brain-first for any customer question. Use mcp__coby-brain__search or query
   to resolve a Fimo entity (by name, email, ID) to a slug (user/<id>, org/<id>,
   project/<id>, prompt/<id>) before drilling into product / support / billing.
2. Use mcp__coby-brain__get_timeline for Fimo-side activity (logins, prompts,
   projects, tours). PostHog (mcp__coby-brain__posthog_*) and Pylon
   (mcp__coby-brain__pylon_*) for what they uniquely hold; Hyperline for
   invoices and subscriptions.
3. Cite slugs in answers (e.g. "Aurélien (`user/abc-123`)") for copy-paste.
4. If the brain returns nothing, say so — never fabricate IDs, emails, activity.
EOF
