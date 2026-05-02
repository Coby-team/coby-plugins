---
description: Sanity-check the coby-brain MCP connection — page counts, last sync, and overall health.
---

Call `mcp__coby-brain__get_stats` and report the result as a compact health snapshot.

Format:

```
coby-brain — <verdict emoji> <verdict word>
URL: https://mcp-production-8831.up.railway.app/mcp

Pages:    users <N>  orgs <N>  projects <N>  prompts <N>
Links:    <N>
Chunks:   <N>  (embedded for hybrid retrieval)
Last sync: <ISO timestamp>  (<human-readable, e.g. "2h ago" / "3 days ago">)
```

Verdict logic:
- ✅ healthy — call succeeded AND last sync is within 24h
- ⚠️ stale — call succeeded but last sync is older than 24h
- ❌ broken — the call itself failed (auth error, network error, 5xx)

If the call fails, do NOT just dump the raw error. Diagnose:
- 401 / 403 → "Auth failed. Check that `COBY_BRAIN_API_KEY` is set in your shell (`echo $COBY_BRAIN_API_KEY`). If empty, export it and restart Claude Code."
- Network / DNS error → "Cannot reach the brain at `mcp-production-8831.up.railway.app`. Check your network, or the Railway deployment status."
- 5xx → "The brain is up but returned a server error. Ping Tom (tom@joincoby.com) with the timestamp."
- Tool not found (`mcp__coby-brain__get_stats` missing) → "The MCP didn't load. Run `claude doctor` to see startup errors, or `claude --debug` for verbose logs."

Keep the output short — one screen, no extra commentary.
