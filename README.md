# Coby plugins for Claude Code

Private marketplace for [Coby](https://joincoby.com) Claude Code plugins. Coby builds a deterministic identity-resolution layer for product agents — this marketplace ships the Claude Code surface for it.

## Plugins

### `coby-brain` (v0.1.0)

Query Coby's identity-resolution brain (users, orgs, projects, prompts) from any Claude Code session. Backed by a remote HTTP MCP deployed on Railway — no local install, no `npx`, no Postgres credentials. Just an API key and you're talking to the brain.

**MCP tools** (read-only, ~14): `search`, `query`, `get_page`, `list_pages`, `get_links`, `get_backlinks`, `traverse_graph`, `get_timeline`, `resolve_slugs`, `find_orphans`, `get_chunks`, `get_raw_data`, `get_stats`, `get_prompt_attachment`. Surface as `mcp__coby-brain__*` tools.

**Slash commands**:
- `/coby-brain:status` — sanity-check brain connection (page counts, last sync, latency, verdict)
- `/coby-brain:user <id|email|slug>` — full user profile (orgs, recent activity, projects, prompts)

**Skills**: `coby-brain-lookup` auto-triggers when the model needs identity data on a Fimo user / org / project / prompt — prevents hallucination by routing to the brain instead of training data.

## Install

You need:
- Claude Code recent version (plugin marketplaces require a current build)
- A Coby brain API key — request from `tom@joincoby.com`
- `gh auth login` already done (this is a private repo; Claude Code uses your gh credentials to clone it)

```bash
# 1. Set your API key — add this to ~/.zshrc or ~/.bashrc to persist
export COBY_BRAIN_API_KEY=sk_coby_...

# 2. Add the marketplace
claude plugin marketplace add Coby-team/coby-plugins

# 3. Install the plugin
claude plugin install coby-brain@coby
```

Verify the connection:

```bash
claude
```
```
> /coby-brain:status
```

You should see something like `coby-brain — ✅ healthy` plus page counts.

## Updating

```bash
claude plugin marketplace update coby
claude plugin install coby-brain@coby --force
```

For headless / CI updates, set `GITHUB_TOKEN` so the marketplace can pull without an interactive `gh` flow.

## Troubleshooting

- **`/coby-brain:status` returns auth error** — check `echo $COBY_BRAIN_API_KEY` prints your key. If empty, your shell didn't pick up the export — open a new terminal or re-source your rc.
- **`mcp__coby-brain__*` tools not visible to Claude** — the MCP didn't start. Run `claude doctor` for MCP load errors, or `claude --debug` to see what failed at boot.
- **Slash commands `/coby-brain:status` not found** — re-run `claude plugin install coby-brain@coby --force` to refresh the install.
- **Marketplace add fails with permission error** — `gh auth status` to verify you can clone the private repo. If `gh` isn't installed, install it (`brew install gh` / `apt install gh`) and `gh auth login`.

## License

Internal use only — not for redistribution.
