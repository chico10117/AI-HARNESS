# 0013 — OpenClaw gateway timeouts: existing agents 10 minutes, new agents 5

**Superseded policy:** the operator clarified that five minutes applies to new
agents outside OpenClaw. [Decision 0014](0014-agent-timeout-policy-correction.md)
records the corrected defaults: OpenClaw ten minutes, other new agents five.
The sections below retain the initial deployment history.

- Date: 2026-10-08
- Status: applied and verified; Paperclip restarted during an idle window.
- Scope: recoVPS Paperclip managed npm `2026.1001.0`, company Chikocorp.
- Authorization: operator requested a longer timeout for all OpenClaw jobs,
  then specified a 5-minute default for new agents.

## Reason

Jarvis run `2e1fe215-3d5f-47c5-bcb5-79f42ea96a98` timed out after
120,000 ms while researching the two articles in CHI-43. It started at
05:52:51 UTC; Paperclip stopped waiting at 05:54:51. The agent saved both
drafts and marked the issue done around 05:55:15. The Mac showed the VPS run
status through its SSH tunnel; this was an adapter timeout, not a Mac timeout.

The execution limit and `agent.wait` limit must both allow sufficient time.
Raising only `timeoutSec` leaves an explicit short `waitTimeoutMs` in effect.
A Paperclip wait timeout does not prove the remote agent has stopped, so do
not automatically replay a timed-out job or overwrite completed artifacts.

## Applied policy

| OpenClaw configuration | `timeoutSec` | `waitTimeoutMs` |
| --- | ---: | ---: |
| Existing Jarvis and `ops` | 600 | 600000 |
| New-agent creation defaults | 300 | 300000 |
| Runtime config with neither field set | 300 | 300000 |

All companies and agents were inspected; Jarvis and `ops` were the only
`openclaw_gateway` agents. Both were updated through partial API PATCHes,
preserving every unrelated adapter setting. Existing issue overrides were
checked; none applied to these agents at the time of the change. Explicit
timeout overrides remain supported. Other adapters keep their existing defaults.

The old run retains its historical timeout status. CHI-43 was already done;
no article generation or other real agent trial was started for verification.

## Installed changes

These changes live in the active payload, not this repository's application
code. Paths below are relative to
`/home/paperclip/.paperclip/cli/installs/npm/2026.1001.0/`:

1. `node_modules/@paperclipai/adapter-openclaw-gateway/dist/server/execute.js`:
   unset `timeoutSec` falls back to 300 seconds. Without an explicit
   `waitTimeoutMs`, the existing runtime rule uses `timeoutSec * 1000`.
2. `node_modules/@paperclipai/adapter-openclaw-gateway/dist/ui/build-config.js`:
   unset creation fields become 300 seconds and 300000 milliseconds.
3. `node_modules/@paperclipai/adapter-openclaw-gateway/dist/index.js`:
   adapter configuration documentation reports the 300-second default.
4. `node_modules/@paperclipai/server/dist/services/heartbeat-stop-metadata.js`:
   OpenClaw's reported default matches 300 seconds; other adapters are unchanged.
5. `node_modules/@paperclipai/server/ui-dist/`: served creation builder and
   timeout input defaults/placeholders match 300 / 300000. Ten JavaScript assets
   in the root bundle's reverse import closure have new `-openclaw300.js` URLs;
   `index.html` loads them. This avoids the one-year immutable asset cache and
   keeps code-split imports using the same application runtime. Original assets
   remain available for already-open tabs.

The initial 600-second UI copies were superseded when the operator specified
five minutes for new agents. Those ten `-openclaw600.js` copies remain available
for tabs opened during the change; current HTML uses only the 300-second copies.
Reload a previously opened tab before creating an agent.

Backups and the SHA-256 manifest are stored as `paperclip` outside Git:

`/data/paperclip/operator-backups/openclaw-timeouts-20261008T060101Z/`

- `agent-timeouts.json`: previous timeout fields only; no credentials.
- `files/`: original four modules and original `index.html`.
- `manifest.json`: payload path, final policy, original/final hashes, and created
  asset paths. Original asset files were preserved rather than overwritten.
- `verify-defaults.mjs`: bounded verification against a loopback mock gateway.

An upgrade can overwrite the module and UI changes. Compare the next release
before carrying the defaults forward; preserve the existing Bubblewrap and
Codex model patches as well. Agent timeout fields persist in the database.

## Verification

- JavaScript syntax checks passed for every changed module and generated asset.
- Module and served-bundle builders produce 300 / 300000 for unset fields and
  preserve explicit 600 / 600000 overrides.
- A local mock WebSocket gateway exercised the installed adapter's actual
  `execute` path: both the `agent` request and `agent.wait` request received
  300000 ms by default and 600000 ms with explicit existing-agent settings.
  An immediate mock timeout retained the expected timeout classification.
- Stop metadata reports the matching OpenClaw default and preserves other
  adapters' defaults. No model invocation, real task replay, or provider spend
  was needed for these checks.
- Paperclip was restarted at 06:11:46 UTC only after two API checks found zero
  live runs. The previously active CHI-44 run had already been cancelled at
  06:11:41 UTC; this change did not cancel it or restart an active worker.
  The unit returned active/running, PID 2592591, with no automatic restarts.
- API health returned `status=ok`, `authReady=true`, startup recovery `ready`.
  Both agent settings remained 600 / 600000 after restart. Current HTML uses
  the new bundle URL, and all ten versioned UI assets returned HTTP 200 with
  bytes matching the verified installed files. OpenClaw health remained live.
- SHA-256 checks confirmed the previous Bubblewrap and Codex model patches
  were unchanged. Backups match the original module and HTML bytes.

## Rollback

First inspect active runs and wait for an idle window before restarting
Paperclip. Read `manifest.json` as `paperclip`, confirm that the active payload
is the recorded version, and compare hashes before overwriting any file.

Restore each manifest entry with `existed=true` from `files/<path>` to the
matching payload path. The original HTML again references the original assets.
Generated assets can remain available for open tabs; remove only manifest-listed
created assets after confirming they are no longer referenced. Do not touch
unrelated files or the existing Bubblewrap/Codex patches.

Restore only the old timing fields from `agent-timeouts.json` through partial
agent PATCHes. The API merges config keys, so a previously absent field must be
removed with a complete current config plus `replaceAdapterConfig=true`, after
comparing it with the latest agent config to preserve unrelated changes.
Never send a stale full adapter config or print its credentials.

Restart only `paperclipai.service` as user `paperclip` with
`XDG_RUNTIME_DIR=/run/user/1002`, then verify API health and timeout settings.
OpenClaw, Docker, PostgreSQL configuration, and network settings do not need
changes for this rollback.
