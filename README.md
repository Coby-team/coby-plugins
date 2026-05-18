# Coby plugins for Claude Code

Private marketplace for [Coby](https://joincoby.com) Claude Code plugins. Coby builds a deterministic identity-resolution layer for product agents — this marketplace ships the Claude Code surface for it.

## Plugins

### `coby-brain` (v0.9.0)

The Coby brain plugged into Claude Code. One install gives every Claude Code session expert-level access to your users, your product activity, your support backlog, and your billing — all served by Coby's hosted brain through a single MCP.

**Bundled MCPs**

| MCP namespace | Purpose | Auth |
|---|---|---|
| `mcp__coby-brain__*` | Identity resolution + curated PostHog (product analytics) + curated Pylon (customer support) + curated Hyperline (billing) + Linear (project management) — all served by Coby's hosted brain (read-only) | Bearer (prompted at install, stored in `~/.claude/settings.json`) |

> **Notion is intentionally not in v1.** Notion has no per-user join key, so it falls outside Coby's identity-resolution scope. If you need Notion in Claude Code, install [Notion's official MCP](https://mcp.notion.com/mcp) separately.

**Skills**
- `customer-profile` — auto-triggers when you ask about a Fimo user; composes brain identity + PostHog + Pylon + Hyperline + Linear into a one-page profile

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

No per-vendor OAuth is needed — the brain serves PostHog, Pylon, Hyperline, and Linear tools using Coby-managed workspace tokens.

Verify end-to-end by asking Claude a customer question — e.g. *"tell me about &lt;a known Fimo user&gt;"*. Claude resolves via `mcp__coby-brain__search` then composes live signals from PostHog (`mcp__coby-brain__posthog_*`), Pylon (`mcp__coby-brain__pylon_*`), Hyperline (`mcp__coby-brain__hyperline_*`), and Linear (`mcp__coby-brain__linear_*`).

## Updating

```bash
claude plugin marketplace update coby
claude plugin install coby-brain@coby --force
```

For headless / CI environments, set `GITHUB_TOKEN` so the marketplace can pull without an interactive `gh` flow.

## Troubleshooting

- **`mcp__coby-brain__*` tools fail with auth error** — your stored API key is invalid (revoked, mistyped, etc.). Re-trigger the install prompt: `claude plugin install coby-brain@coby --force`. Paste your key again.
- **`mcp__coby-brain__*` tools missing in Claude** — the brain MCP didn't load. Run `claude doctor` for MCP errors, or `claude --debug` to see startup failures. Check that you completed the API-key prompt at install time.
- **Vendor tools fail (`mcp__coby-brain__posthog_*` / `mcp__coby-brain__pylon_*` / `mcp__coby-brain__hyperline_*` / `mcp__coby-brain__linear_*`)** — they're all served by the brain, so failures point to the brain MCP, not the vendor. Run `mcp__coby-brain__get_health` first; if that's green, the vendor token in the brain's DB may have rotated — ping `tom@joincoby.com`.
- **Marketplace add fails with permission error** — `gh auth status` to verify access. If `gh` isn't installed: `brew install gh` / `apt install gh`, then `gh auth login`.

## License

Internal use only — not for redistribution.
