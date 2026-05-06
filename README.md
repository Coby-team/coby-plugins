# Coby plugins for Claude Code

Private marketplace for [Coby](https://joincoby.com) Claude Code plugins. Coby builds a deterministic identity-resolution layer for product agents — this marketplace ships the Claude Code surface for it.

## Plugins

### `coby-brain` (v0.6.0)

The Coby brain plugged into Claude Code. One install gives every Claude Code session expert-level access to your users, your product activity, and your billing — by composing Coby's identity-resolution brain with the curated vendor tools it serves and one official vendor MCP for billing.

**Bundled MCPs**

| MCP namespace | Purpose | Auth |
|---|---|---|
| `mcp__coby-brain__*` | Identity resolution + curated PostHog (product analytics) and Pylon (customer support) tool sets — all served by Coby's hosted brain (49 tools) | Bearer (prompted at install, stored in `~/.claude/settings.json`) |
| `mcp__hyperline__*` | Subscription billing — customers, subscriptions, invoices (~100 tools) | Browser OAuth |

> **Notion is intentionally not in v1.** Notion has no per-user join key, so it falls outside Coby's identity-resolution scope. If you need Notion in Claude Code, install [Notion's official MCP](https://mcp.notion.com/mcp) separately.

**Skills**
- `customer-profile` — auto-triggers when you ask about a Fimo user; composes brain + PostHog + Pylon + Hyperline into a one-page profile

## Install

You need:
- Claude Code recent version (plugin marketplaces require a current build)
- A Coby brain API key — request from `tom@joincoby.com`
- `gh auth login` already done (this is a private repo)

```bash
# 1. Add the marketplace
claude plugin marketplace add Coby-team/coby-plugins

# 2. Install the plugin
claude plugin install coby-brain@coby
```

When the plugin is enabled, **Claude Code prompts you for your Coby brain API key** — paste it once. It's stored in `~/.claude/settings.json` under `pluginConfigs.coby-brain.options.api_key`, and you never need to type it again on this machine. No env var, no shell rc edits. Don't commit, screenshot, or share that file — treat it like an SSH key.

The first time you use a Hyperline tool (`mcp__hyperline__*`) in a Claude Code session, your browser opens to Hyperline's OAuth screen — click "Allow", and Claude Code caches the token. **One OAuth, once.** PostHog and Pylon need no per-user OAuth: the brain serves their curated tools using Coby's workspace-level tokens.

Verify end-to-end by asking Claude a customer question — e.g. *"tell me about &lt;a known Fimo user&gt;"*. Claude resolves via `mcp__coby-brain__search` then composes live signals from PostHog (`mcp__coby-brain__posthog_*`), Pylon (`mcp__coby-brain__pylon_*`), and Hyperline (`mcp__hyperline__*`, OAuth on first use).

## Updating

```bash
claude plugin marketplace update coby
claude plugin install coby-brain@coby --force
```

For headless / CI environments, set `GITHUB_TOKEN` so the marketplace can pull without an interactive `gh` flow.

## Troubleshooting

- **`mcp__coby-brain__*` tools fail with auth error** — your stored API key is invalid (revoked, mistyped, etc.). Re-trigger the install prompt: `claude plugin install coby-brain@coby --force`. Paste your key again.
- **`mcp__coby-brain__*` tools missing in Claude** — the brain MCP didn't load. Run `claude doctor` for MCP errors, or `claude --debug` to see startup failures. Check that you completed the API-key prompt at install time.
- **Hyperline tools (`mcp__hyperline__*`) missing** — invoke one in chat and Claude Code should trigger the OAuth flow. If nothing happens, run `claude --debug` and look for `mcpServers` errors.
- **PostHog or Pylon tools fail (`mcp__coby-brain__posthog_*` / `mcp__coby-brain__pylon_*`)** — they're served by the brain, so failures point to the brain MCP, not the vendor. Run `mcp__coby-brain__get_health` first; if that's green, the vendor token in the brain's DB may have rotated — ping `tom@joincoby.com`.
- **Hyperline OAuth token expired in the middle of work** — Hyperline tokens last hours to days. Just trigger the tool again; CC will redo the OAuth flow.
- **Marketplace add fails with permission error** — `gh auth status` to verify access. If `gh` isn't installed: `brew install gh` / `apt install gh`, then `gh auth login`.

## License

Internal use only — not for redistribution.
