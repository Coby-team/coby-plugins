# coby-plugins

Private Claude Code plugin marketplace for Coby. Ships the `coby-brain` plugin — a single product surface that bundles Coby's identity-resolution brain (HTTP MCP on Railway, which now also serves curated PostHog and Pylon tool sets) with one official vendor MCP for billing (Hyperline).

The plugin is one cohesive software, not a thin distribution wrapper. The differentiation is in the **glue** between the brain and the vendors — skills and commands compose them (e.g. resolve a user via the brain, then fetch their tickets via the brain's Pylon tools), so Claude Code becomes an expert on each tenant's product and users.

## Architecture decisions (locked for v1)

- **One plugin, two MCPs.** `coby-brain` is the single product surface. `.mcp.json` declares 2 servers: the brain (which serves brain + curated PostHog + curated Pylon) and the official Hyperline MCP. Auth: a `userConfig`-prompted Bearer for the brain (stored in `~/.claude/settings.json` since v0.4.0 — `sensitive: false` chosen to enable an external `npx @coby/init` wizard to pre-fill it; trade-off is plain-text in settings.json instead of OS keychain), browser OAuth for Hyperline.
- **PostHog and Pylon served by the brain, not as separate vendor MCPs.** Switched in v0.6.0 (was 4 MCPs in v0.4–v0.5). Reasons: (1) the brain can apply curated tool sets — 14 PostHog tools and 17 Pylon tools instead of 200+ noisy ones — keeping the agent's tool surface manageable; (2) workspace-level tokens stored in the brain's `user_integrations` table mean end users don't OAuth per-vendor; (3) the brain's response shapes (compact tables, error enrichment, write-op guards on HogQL, filter validation on Pylon) are tighter than what the vendor MCPs return.
- **Hyperline kept as a separate vendor MCP for now.** The brain has zero Hyperline mapping (no `connect-coby` ↔ Hyperline customer-id bridge yet), so the brain can't curate it usefully. Promote it into the brain when that bridge lands.
- **No Coby-built generic proxy MCP.** Plan B (proxy via connect-coby) is on the shelf for the case where a vendor's MCP becomes a hard dependency we want to wrap. Not the default.
- **Notion intentionally out of scope** for v1. Per the `coby-brain-mcp` (formerly `coby-users-database`) charter, Notion has no per-user join key — it doesn't fit the brain's mapping. Users can install Notion's MCP separately if they want.

## Plugin surface

The **marketplace + plugin structure** plus the **MCP wiring** is the validated v0.6 deliverable. The first real skill (`customer-profile`) composes the brain (which holds identity + curated PostHog + curated Pylon tool sets) with the Hyperline vendor MCP. Slash commands are deferred — `commands/` is kept as an empty stub for future additions.

**Real surface (do not regress):**
- `.claude-plugin/marketplace.json` — marketplace manifest, monorepo `metadata.pluginRoot`
- `plugins/coby-brain/.claude-plugin/plugin.json` — plugin manifest (current version `0.6.0`)
- `plugins/coby-brain/.mcp.json` — bundles 2 MCP servers:
  - `coby-brain` → `https://brain.joincoby.com/mcp` (Bearer `${user_config.api_key}`, prompted at install via plugin's `userConfig`, `sensitive: false`) — exposes brain identity tools + `posthog_*` + `pylon_*` curated tool sets
  - `hyperline` → `https://mcp.hyperline.co/mcp` (OAuth)
- `plugins/coby-brain/skills/customer-profile/SKILL.md` — composes brain (identity, PostHog, Pylon) + Hyperline into a one-page customer profile (auto-triggered by user/customer questions)
- `plugins/coby-brain/hooks/hooks.json` + `hooks/session_brief.sh` — SessionStart hook that orients Claude Code on the plugin context at every session start
- `README.md` — install + onboarding for end users

## When working here

- **Do not add new MCPs or new vendors** without an explicit ask from Tom. The 2-MCP set (brain + Hyperline) is locked for v1.
- **The brain MCP URL and the Hyperline MCP URL are real product config** — bug fixes there are welcome.
- New skills must compose the brain (which now covers identity + product + support) with Hyperline when billing is needed (`customer-profile` is the reference pattern). Brain-only skills are still useful — the brain alone now answers identity, product, and support questions.
- When dropping or renaming MCPs in `.mcp.json`, grep all skills/commands/hooks for the old `mcp__<name>__*` namespace before pushing — see the v0.6.0 post-mortem in `coby-brain-mcp/docs/superpowers/plans/2026-05-04-vendor-tools-expansion.md`.
- **Never rename or remove `userConfig` field names without a major version bump and a heads-up to existing users.** User secrets live at `pluginSecrets["coby-brain@coby"].<field>` in `~/.claude/.credentials.json`, namespaced by plugin@marketplace + field name. The whole point of plugin updates being safe (config preserved across versions) hinges on this stability. Adding new fields is fine; renaming or removing them silently re-prompts every user for their api_key.
- **Plugin update model.** Bumping `plugin.json.version` and pushing to `main` is enough to trigger auto-update on the user's next Claude Code session (then `/reload-plugins`). The `marketplace.json` does not need a version field — `plugin.json.version` is the single source of truth Claude Code reads. User config (`api_key`, OAuth tokens) lives outside the plugin cache and survives updates by design.
- Don't reach for a Coby-built generic proxy MCP unless you have a measured reason (context cost, missing curation, vendor MCP downtime). Plan B (proxy via connect-coby) is on the shelf, not the default.
