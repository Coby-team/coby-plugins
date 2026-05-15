# coby-plugins

Private Claude Code plugin marketplace for Coby. Ships the `coby-brain` plugin — a single product surface that bundles Coby's identity-resolution brain (HTTP MCP on Railway) and the curated vendor tool sets it serves (PostHog, Pylon, Hyperline).

The plugin is one cohesive software, not a thin distribution wrapper. The differentiation is in the **glue** between identity and vendor data — skills and commands compose them (e.g. resolve a user via the brain, then fetch their tickets via the brain's Pylon tools), so Claude Code becomes an expert on each tenant's product and users.

## Architecture decisions (locked for v1)

- **One plugin, one MCP.** `coby-brain` is the single product surface. `.mcp.json` declares 1 server: the brain, which serves brain identity + curated PostHog + curated Pylon + curated Hyperline. Auth: a `userConfig`-prompted Bearer for the brain, `sensitive: true` (source of truth: `plugins/coby-brain/.claude-plugin/plugin.json`). The api key lands in `~/.claude/.credentials.json` under `pluginSecrets["coby-brain@coby"].api_key` (file mode 0600). History: v0.4.0 flipped `sensitive: false` briefly to let `npx @joincoby/cli init` pre-fill it, but v0.4.1 reverted because Claude Code's native plugin flow expects `.credentials.json` for tokens — the CLI now writes there directly. No per-vendor OAuth.
- **All three vendors served by the brain, not as separate vendor MCPs.** PostHog and Pylon switched in v0.6.0 (was 4 MCPs in v0.4–v0.5); Hyperline followed in v0.8.0 once the `hyperline_customer_id = fimo_org_id` shortcut closed the mapping gap for Fimo. Reasons: (1) the brain applies curated tool sets — 14 PostHog tools, 17 Pylon tools, 10 Hyperline tools, instead of 200+ noisy ones — keeping the agent's tool surface manageable; (2) workspace-level tokens stored in the brain's `user_integrations` table mean end users don't OAuth per-vendor; (3) the brain's response shapes (compact tables, error enrichment, write-op guards on HogQL, filter validation on Pylon) are tighter than what the vendor MCPs return. Hyperline writes (~100 tools: create/update/cancel/charge/void/quotes/coupons/wallets/etc.) are intentionally out of scope for v1 — read-only by design.
- **No Coby-built generic proxy MCP.** Plan B (proxy via connect-coby) is on the shelf for the case where a vendor's MCP becomes a hard dependency we want to wrap. Not the default.
- **Notion intentionally out of scope** for v1. Per the `coby-brain-mcp` (formerly `coby-users-database`) charter, Notion has no per-user join key — it doesn't fit the brain's mapping. Users can install Notion's MCP separately if they want.

## Plugin surface

The **marketplace + plugin structure** plus the **MCP wiring** is the validated deliverable. Two skills shipped so far compose brain identity + curated PostHog + curated Pylon + curated Hyperline — all served by the single brain MCP. Slash commands are deferred — `commands/` is kept as an empty stub for future additions.

**Real surface (do not regress)** — source of truth for version is `plugins/coby-brain/.claude-plugin/plugin.json.version`:
- `.claude-plugin/marketplace.json` — marketplace manifest. Keep `plugins[].description` in sync with the actual MCP/vendor set whenever it changes
- `plugins/coby-brain/.claude-plugin/plugin.json` — plugin manifest (single source of truth for version, userConfig, metadata)
- `plugins/coby-brain/.mcp.json` — bundles 1 MCP server:
  - `coby-brain` → `https://brain.joincoby.com/mcp` (Bearer `${user_config.api_key}`, prompted at install via plugin's `userConfig`, `sensitive: true`) — exposes brain identity tools + `posthog_*` + `pylon_*` + `hyperline_*` curated tool sets
- `plugins/coby-brain/skills/customer-profile/SKILL.md` — composes brain identity, PostHog, Pylon, and Hyperline into a one-page customer profile (auto-triggered by user/customer questions)
- `plugins/coby-brain/skills/product-reflection/SKILL.md` — second skill (shipped v0.7.0)
- `plugins/coby-brain/hooks/hooks.json` + `hooks/session_brief.sh` — SessionStart hook that orients Claude Code on the plugin context at every session start
- `README.md` — install + onboarding for end users

## When working here

- **Do not add new MCPs or new vendors** without an explicit ask from Tom. The 1-MCP set (brain only, serving curated PostHog/Pylon/Hyperline) is locked for v1.
- **The brain MCP URL is real product config** — bug fixes there are welcome.
- New skills use the brain for everything — identity, product, support, billing all live under `mcp__coby-brain__*`. `customer-profile` is the reference pattern.
- When dropping or renaming MCPs or vendor namespaces in `.mcp.json`, grep all skills/commands/hooks/docs for the old `mcp__<name>__*` namespace before pushing — see the v0.6.0 post-mortem in `coby-brain-mcp/docs/superpowers/plans/2026-05-04-vendor-tools-expansion.md`.
- **Never rename or remove `userConfig` field names without a major version bump and a heads-up to existing users.** User secrets live at `pluginSecrets["coby-brain@coby"].<field>` in `~/.claude/.credentials.json`, namespaced by plugin@marketplace + field name. The whole point of plugin updates being safe (config preserved across versions) hinges on this stability. Adding new fields is fine; renaming or removing them silently re-prompts every user for their api_key.
- **Plugin update model.** Bumping `plugin.json.version` and pushing to `main` does **not** auto-update users by default — third-party marketplaces (which `coby` is) ship with auto-update OFF in Claude Code. Users must enable it via `/plugin → Marketplaces → coby → Enable auto-update` (the `coby-cli init` wizard reminds them in its post-install notice). Once enabled, Claude Code refreshes the marketplace at session startup, updates installed plugins to `plugin.json.version`, and prompts `/reload-plugins`. Without auto-update, users must run `/plugin marketplace update coby` + `/reload-plugins` manually. The `marketplace.json` does not need a version field — `plugin.json.version` is the single source of truth Claude Code reads. User config (`api_key`, OAuth tokens) lives outside the plugin cache and survives updates by design. (Anthropic feature request to expose `autoUpdate` programmatically and let third-party marketplace authors flip the default: `anthropics/claude-code#51350` — open as of 2026-05-07.)
- Don't reach for a Coby-built generic proxy MCP unless you have a measured reason (context cost, missing curation, vendor MCP downtime). Plan B (proxy via connect-coby) is on the shelf, not the default.
