# coby-plugins

Private Claude Code plugin marketplace for Coby. Ships the `coby-brain` plugin, which bundles a remote HTTP MCP (deployed on Railway) plus a skill and slash commands.

## What's real vs placeholder

The **marketplace + plugin structure** is the validated deliverable for v0.1. The skill and command **content** is throwaway placeholder, written only to validate that the wiring works end-to-end (skill auto-trigger, slash command invocation, MCP boot). It has **not** been designed against real user needs and will be replaced or deleted.

**Real surface (do not regress):**
- `.claude-plugin/marketplace.json` — marketplace manifest, monorepo `metadata.pluginRoot`
- `plugins/coby-brain/.claude-plugin/plugin.json` — plugin manifest
- `plugins/coby-brain/.mcp.json` — HTTP MCP wiring (Railway URL, `${COBY_BRAIN_API_KEY}` Bearer auth)
- `README.md` — install flow for end users

**Placeholder (slated for deletion or full rewrite):**
- `plugins/coby-brain/skills/coby-brain-lookup/SKILL.md`
- `plugins/coby-brain/commands/status.md`
- `plugins/coby-brain/commands/user.md`

## When working here

- **Do not polish the placeholders.** No expanding their content, no adding edge cases, no treating their behavior as a contract.
- **Do not add more skills or commands** "in the same vein" without an explicit ask from Tom — the real surface design is TBD.
- The MCP config, `marketplace.json`, and `plugin.json` are real product — bug fixes and structural improvements there are welcome.
- When Tom asks for the real skills/commands, **replace** the placeholders entirely rather than editing them in place.
