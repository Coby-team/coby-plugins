# coby-plugins

Private Claude Code plugin marketplace for Coby. Ships the `coby-brain` plugin — a single product surface that bundles Coby's identity-resolution brain (HTTP MCP on Railway) and the curated vendor tool sets it serves (PostHog, Pylon, Hyperline, Linear).

The plugin is one cohesive software, not a thin distribution wrapper. The differentiation is in the **glue** between identity and vendor data — skills and commands compose them (e.g. resolve a user via the brain, then fetch their tickets via the brain's Pylon tools), so Claude Code becomes an expert on each tenant's product and users.

## Architecture decisions (locked for v1)

- **One plugin, one MCP.** `coby-brain` is the single product surface. `.mcp.json` declares 1 server: the brain, which serves brain identity + curated PostHog + curated Pylon + curated Hyperline + Linear (proxy). Auth: a `userConfig`-prompted Bearer for the brain, `sensitive: true` (source of truth: `plugins/coby-brain/.claude-plugin/plugin.json`). The api key lands in `~/.claude/.credentials.json` under `pluginSecrets["coby-brain@coby"].api_key` (file mode 0600). History: v0.4.0 flipped `sensitive: false` briefly to let `npx @joincoby/cli init` pre-fill it, but v0.4.1 reverted because Claude Code's native plugin flow expects `.credentials.json` for tokens — the CLI now writes there directly. No per-vendor OAuth.
- **All vendors served by the brain, not as separate vendor MCPs.** PostHog and Pylon switched in v0.6.0 (was 4 MCPs in v0.4–v0.5); Hyperline followed in v0.8.0 once the `hyperline_customer_id = fimo_org_id` shortcut closed the mapping gap for Fimo; Linear added in v0.9.0 via the proxy MCP-to-MCP pattern (no curation layer needed, Linear has a hosted MCP). Reasons: (1) the brain applies curated tool sets — a few dozen tools instead of the 200+ the native MCPs expose — keeping the agent's tool surface manageable (source of truth for the current count per vendor: `coby-brain-mcp/src/mcp/tools.ts`); (2) workspace-level tokens stored in the brain's `user_integrations` table mean end users don't OAuth per-vendor; (3) the brain's response shapes (compact tables, error enrichment, write-op guards on HogQL, filter validation on Pylon) are tighter than what the vendor MCPs return. Hyperline writes (create/update/cancel/charge/void/quotes/coupons/wallets/…) are intentionally out of scope for v1 — read-only by design.
- **No Coby-built generic proxy MCP.** Plan B (proxy via connect-coby) is on the shelf for the case where a vendor's MCP becomes a hard dependency we want to wrap. Not the default.
- **Notion intentionally out of scope** for v1. Per the `coby-brain-mcp` (formerly `coby-users-database`) charter, Notion has no per-user join key — it doesn't fit the brain's mapping. Users can install Notion's MCP separately if they want.

## Plugin surface

The **marketplace + plugin structure** plus the **MCP wiring** is the validated deliverable. Two skills shipped so far compose brain identity + curated PostHog + curated Pylon + curated Hyperline + Linear (proxy) — all served by the single brain MCP. Slash commands are deferred — `commands/` is kept as an empty stub for future additions.

**Real surface (do not regress)** — source of truth for version is `plugins/coby-brain/.claude-plugin/plugin.json.version`:
- `.claude-plugin/marketplace.json` — marketplace manifest. Keep `plugins[].description` in sync with the actual MCP/vendor set whenever it changes
- `plugins/coby-brain/.claude-plugin/plugin.json` — plugin manifest (single source of truth for version, userConfig, metadata)
- `plugins/coby-brain/.mcp.json` — bundles 1 MCP server:
  - `coby-brain` → `https://brain.joincoby.com/mcp` (Bearer `${user_config.api_key}`, prompted at install via plugin's `userConfig`, `sensitive: true`) — exposes brain identity tools + `posthog_*` + `pylon_*` + `hyperline_*` curated tool sets + `linear_*` (proxy to Linear's hosted MCP)
- `plugins/coby-brain/skills/customer-profile/SKILL.md` — composes brain identity, PostHog, Pylon, and Hyperline into a one-page customer profile (auto-triggered by user/customer questions)
- `plugins/coby-brain/skills/product-reflection/SKILL.md` — second skill (shipped v0.7.0)
- `plugins/coby-brain/hooks/hooks.json` + `hooks/session_brief.sh` — SessionStart hook that orients Claude Code on the plugin context at every session start
- `README.md` — install + onboarding for end users

## Key invariants — do not break

- **One plugin, one MCP server (the brain) — always.** Vendors are added TO the brain, never as separate MCP entries in `.mcp.json`. Use **proxy MCP-to-MCP** when the upstream vendor offers a hosted MCP AND no curation is needed beyond what they expose. Use **custom REST/GraphQL handlers** in the brain when there's no hosted MCP, OR when curation is needed (read-only enforcement, identity injection, response transformation, etc.). Linear (proxy) and PostHog/Pylon/Hyperline (custom) are the two reference examples. See `../coby-brain-mcp/docs/superpowers/plans/2026-05-18-linear-proxy.md` for the proxy pattern.
- **Never rename or remove `userConfig` field names** without a major version bump and a heads-up to existing users. Secrets live at `pluginSecrets["coby-brain@coby"].<field>` in `~/.claude/.credentials.json`, namespaced by `plugin@marketplace + field`. Plugin updates only stay safe (config preserved across versions) because field names are stable — renaming or removing them silently re-prompts every user. Adding new fields is fine.
- **Don't reach for a Coby-built generic proxy MCP** unless you have a measured reason (context cost, missing curation, vendor MCP downtime). Plan B (proxy via `connect-coby`) is on the shelf, not the default.
- **Keep `marketplace.json.plugins[].description` in sync with the actual MCP/vendor set.** It drifted in v0.6/v0.8 transitions; users read it before installing.

## Guidelines (when working here)

- The brain MCP URL is real product config — bug fixes are welcome.
- New skills use the brain for everything — identity, product, support, billing all live under `mcp__coby-brain__*`. `customer-profile` is the reference pattern; `product-reflection` (v0.7.0) is the second.
- When dropping or renaming MCPs or vendor namespaces in `.mcp.json`, grep all skills/commands/hooks/docs for the old `mcp__<name>__*` namespace before pushing — see the v0.6.0 post-mortem in `coby-brain-mcp/docs/superpowers/plans/2026-05-04-vendor-tools-expansion.md`.

## Tech notes — per brick

### Claude Code plugin model

**Source of truth for version: `plugins/coby-brain/.claude-plugin/plugin.json.version`.** Claude Code reads this. `marketplace.json` does not carry a version field — never add one.

**Third-party marketplaces ship with auto-update OFF.** Bumping `plugin.json.version` and pushing to `main` does **not** auto-update users by default — `coby` is a third-party marketplace (not an Anthropic-curated one), and Claude Code ships those with auto-update disabled. Users have two options:

- **Enable auto-update once**: `/plugin → Marketplaces → coby → Enable auto-update`. After that, Claude Code refreshes the marketplace at session startup, updates installed plugins to the new `plugin.json.version`, and prompts `/reload-plugins`. The `coby-cli init` wizard's post-install notice reminds users to do this.
- **Update manually each time**: `/plugin marketplace update coby` + `/reload-plugins`.

Tracking issue to expose `autoUpdate` programmatically so third-party marketplaces can flip the default: `anthropics/claude-code#51350` (open as of 2026-05-07).

**User config survives updates by design.** `pluginSecrets["coby-brain@coby"].api_key` lives in `~/.claude/.credentials.json`, namespaced by `plugin@marketplace + field`. The credentials file is outside the plugin cache. A plugin version bump doesn't touch it — unless we rename a `userConfig` field (see invariant above).

**SessionStart hook (`hooks/session_brief.sh`).** Runs once per session, prints a brief that orients Claude Code on the plugin context (which tools are under `mcp__coby-brain__*`, which skills exist, default routing). When skills are added/renamed, update the hook content. When MCP namespaces change in `.mcp.json`, the brief must reflect the new prefix.

### SessionStart hook Recovery section

The `hooks/session_brief.sh` brief includes a Recovery section that tells
Claude what to do when `mcp__coby-brain__*` tools are missing or returning
auth errors: suggest `npx @joincoby/cli doctor` to the user, optionally
run `--diagnose-only` first to confirm. Static text — no shell-out, no
disk read, no preemptive check. The dynamic diagnosis is opt-in by Claude
via the CLI's `--diagnose-only` mode. Pattern documented in
`/home/tom/projects/coby-brain/docs/superpowers/specs/2026-05-18-doctor-command-design.md`.

### Plugin manifest fields

`plugin.json.userConfig` drives the install-time prompt. The `sensitive: true` flag determines storage path: `true` → `.credentials.json`, `false` → `settings.json`. We use `true` (history: v0.4.0 tried `false` for CLI pre-fill, v0.4.1 reverted because the CLI now writes the same `.credentials.json` path directly). When adding a new userConfig field, default to `sensitive: true` unless the value is genuinely not a secret.

## Release workflow

Before tagging a new plugin version:

1. **Bump `plugin.json.version`** (semver). This is the source-of-truth field Claude Code reads.
2. **Sync `marketplace.json.plugins[].description`** if the MCP set or vendor curation changed. Drift here mis-sells the plugin to potential installers.
3. **Update `hooks/session_brief.sh`** if skills/commands/MCPs/tool namespaces changed — the brief is read literally by every session.
4. **Grep `mcp__<name>__*` across the repo** if a vendor MCP or namespace moved. Skills/commands referring to a removed namespace will silently no-op.
5. **Commit + push to `main`.** Auto-update OFF by default for third-party marketplaces — users on auto-update will pick it up next session; others must run `/plugin marketplace update coby` + `/reload-plugins`.
6. **No marketplace.json version bump** — there is no version field on the marketplace. Don't add one.
