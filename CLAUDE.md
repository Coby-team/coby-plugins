# coby-plugins

Private Claude Code plugin marketplace for Coby. Ships the `coby-brain` plugin — a single product surface that bundles Coby's identity-resolution brain (HTTP MCP on Railway) with the official vendor MCPs Coby's customers query in their day-to-day: PostHog, Pylon, Hyperline.

The plugin is one cohesive software, not a thin distribution wrapper. The differentiation is in the **glue** between the brain and the vendors — skills and commands compose them (e.g. resolve a user via the brain, then fetch their tickets via Pylon), so Claude Code becomes an expert on each tenant's product and users.

## Architecture decisions (locked for v1)

- **One plugin, multiple MCPs.** `coby-brain` is the single product surface. `.mcp.json` declares 4 servers (brain + 3 vendors). Auth is per-MCP independently: a `userConfig`-prompted Bearer for the brain (stored in `~/.claude/settings.json` since v0.4.0 — `sensitive: false` chosen to enable an external `npx @coby/init` wizard to pre-fill it; trade-off is plain-text in settings.json instead of OS keychain), browser OAuth for the vendors.
- **Vendor official MCPs, no Coby proxy.** No Railway-hosted proxy that wraps connect-coby's call layer. Custom MCPs are deferred until measured (PostHog at ~200 tools is the candidate to evaluate first if context cost is a problem).
- **Notion intentionally out of scope** for v1. Per the `coby-brain-mcp` (formerly `coby-users-database`) charter, Notion has no per-user join key — it doesn't fit the brain's mapping. Users can install Notion's MCP separately if they want.
- **Hyperline shipped despite connect-coby gap.** The vendor MCP is wired in even though connect-coby has zero Hyperline integration today. Trade-off: Aurélien gets billing tools immediately, but the brain can't yet map Coby user IDs ↔ Hyperline customer IDs. Bridge that in connect-coby later.

## Plugin surface

The **marketplace + plugin structure** plus the **MCP wiring** is the validated v0.3 deliverable. The first real skill (`customer-profile`) composes the brain with the three vendor MCPs. Slash commands are deferred — `commands/` is kept as an empty stub for future additions.

**Real surface (do not regress):**
- `.claude-plugin/marketplace.json` — marketplace manifest, monorepo `metadata.pluginRoot`
- `plugins/coby-brain/.claude-plugin/plugin.json` — plugin manifest
- `plugins/coby-brain/.mcp.json` — bundles 4 MCP servers:
  - `coby-brain` → `https://brain.joincoby.com/mcp` (Bearer `${user_config.api_key}`, prompted at install via plugin's `userConfig`, `sensitive: false`)
  - `posthog` → `https://mcp.posthog.com/mcp` (OAuth)
  - `pylon` → `https://mcp.usepylon.com` (OAuth, requires Member/Admin seat)
  - `hyperline` → `https://mcp.hyperline.co/mcp` (OAuth)
- `plugins/coby-brain/skills/customer-profile/SKILL.md` — composes brain + 3 vendor MCPs into a one-page customer profile (auto-triggered by user/customer questions)
- `plugins/coby-brain/hooks/hooks.json` + `hooks/session_brief.sh` — SessionStart hook that orients Claude Code on the plugin context at every session start
- `README.md` — install + per-vendor onboarding for end users

## When working here

- **Do not add new MCPs or new vendors** without an explicit ask from Tom. The 4-MCP set is locked for v1.
- **Vendor MCP URLs and the brain MCP URL are real product config** — bug fixes there are welcome.
- New skills must compose `coby-brain` + vendor MCPs (`customer-profile` is the reference pattern). Brain-only skills regress the differentiation — the brain alone is just identity resolution.
- Don't reach for a Coby-built proxy MCP unless you have a measured reason (context cost, missing curation, vendor MCP downtime). Plan B (proxy via connect-coby) is on the shelf, not the default.
