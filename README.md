# Coby plugins for Claude Code

Private marketplace for [Coby](https://joincoby.com) Claude Code plugins. Coby builds a deterministic identity-resolution layer for product agents — this marketplace ships the Claude Code surface for it.

## Plugins

### `coby-brain` (v0.3.0)

The Coby brain plugged into Claude Code. One install gives every Claude Code session expert-level access to your users, your product activity, and your billing — by composing Coby's identity-resolution brain with the official MCPs of the tools you already use.

**Bundled MCPs**

| MCP namespace | Purpose | Auth |
|---|---|---|
| `mcp__coby-brain__*` | Identity resolution: users, orgs, projects, prompts (Coby's hosted brain) | Bearer (prompted at install, stored in OS keychain) |
| `mcp__posthog__*` | Product analytics — sessions, events, feature flags, errors (~200 tools) | Browser OAuth |
| `mcp__pylon__*` | Customer support — issues, accounts, contacts (~13 tools) | Browser OAuth |
| `mcp__hyperline__*` | Subscription billing — customers, subscriptions, invoices (~100 tools) | Browser OAuth |

> **Notion is intentionally not in v1.** Notion has no per-user join key, so it falls outside Coby's identity-resolution scope. If you need Notion in Claude Code, install [Notion's official MCP](https://mcp.notion.com/mcp) separately.

**Slash commands** *(placeholder — will be replaced with cross-source workflows)*
- `/coby-brain:status` — sanity-check brain connection
- `/coby-brain:user <id|email|slug>` — user profile from the brain

**Skills** *(placeholder — will be replaced)*
- `coby-brain-lookup` — auto-triggers on Fimo identity questions

## Install

You need:
- Claude Code recent version (plugin marketplaces require a current build)
- A Coby brain API key — request from `tom@joincoby.com`
- `gh auth login` already done (this is a private repo)
- A **Member or Admin seat** in your Pylon workspace (Pylon's MCP rejects Viewer / Integration users)

```bash
# 1. Add the marketplace
claude plugin marketplace add Coby-team/coby-plugins

# 2. Install the plugin
claude plugin install coby-brain@coby
```

When the plugin is enabled, **Claude Code prompts you for your Coby brain API key** — paste it once. It's stored in your OS keychain (not in `settings.json`), and you never need to type it again on this machine. No env var, no shell rc edits.

The first time you use any vendor tool (`mcp__posthog__*`, `mcp__pylon__*`, `mcp__hyperline__*`) in a Claude Code session, your browser opens to the vendor's OAuth screen — click "Allow", and Claude Code caches the token. **One OAuth per vendor, once.**

Verify the brain side end-to-end:

```bash
claude
```
```
> /coby-brain:status
```

You should see `coby-brain — ✅ healthy` plus page counts. To verify a vendor is wired correctly, ask Claude something the vendor can answer (e.g. "list our last 5 PostHog feature flags") and watch the OAuth flow trigger.

## Updating

```bash
claude plugin marketplace update coby
claude plugin install coby-brain@coby --force
```

For headless / CI environments, set `GITHUB_TOKEN` so the marketplace can pull without an interactive `gh` flow.

## Troubleshooting

- **`/coby-brain:status` returns auth error** — your stored API key is invalid (revoked, mistyped, etc.). Re-trigger the install prompt: `claude plugin install coby-brain@coby --force`. Paste your key again.
- **`mcp__coby-brain__*` tools missing in Claude** — the brain MCP didn't load. Run `claude doctor` for MCP errors, or `claude --debug` to see startup failures. Check that you completed the API-key prompt at install time.
- **Vendor tools (`mcp__posthog__*`, `mcp__pylon__*`, `mcp__hyperline__*`) missing** — invoke one in chat and Claude Code should trigger the OAuth flow. If nothing happens, run `claude --debug` and look for `mcpServers` errors.
- **Pylon OAuth fails with "your seat doesn't allow this"** — Pylon requires a Member or Admin seat for MCP access. Ask your workspace owner to upgrade your seat.
- **OAuth token expired in the middle of work** — vendor tokens last hours to days depending on the vendor. Just trigger the tool again; CC will redo the OAuth flow.
- **Marketplace add fails with permission error** — `gh auth status` to verify access. If `gh` isn't installed: `brew install gh` / `apt install gh`, then `gh auth login`.

## License

Internal use only — not for redistribution.
