# 0014 — Creation defaults: OpenClaw 10 minutes, other agents 5

- Date: 2026-10-08
- Status: applied; service reloaded during an idle window and API ready.
- Scope: recoVPS Paperclip managed npm `2026.1001.0`.
- Supersedes the new-agent policy in [0013](0013-openclaw-default-timeouts.md).

The operator clarified that the requested five-minute default applies to new
agents outside OpenClaw, including Codex. OpenClaw keeps ten minutes for both
existing and new agents. Existing non-OpenClaw agents retain their individual
settings, including disabled limits and longer configured limits.

## Policy and implementation

| New agent | Default config |
| --- | --- |
| OpenClaw | `timeoutSec=600`, `waitTimeoutMs=600000` |
| Other adapters | `timeoutSec=300` |
| HTTP | `timeoutMs=300000` |

Explicit config values, including zero, override creation defaults. For HTTP,
an explicit `timeoutSec` is converted to milliseconds only when `timeoutMs`
is absent. OpenClaw's unset wait timeout follows an explicit positive
`timeoutSec`; an explicit `waitTimeoutMs` remains authoritative.

Installed changes under the active payload's `node_modules`:

- `@paperclipai/server/dist/services/new-agent-timeout-defaults.js`: pure
  creation-default helper, called only by `agentService.create` in `agents.js`.
  Existing-agent updates and non-OpenClaw runtime fallback rules are untouched.
- OpenClaw adapter runtime, UI builder, configuration documentation, and
  heartbeat stop metadata: default restored to 600 seconds / 600000 ms.
- Eight local adapter UI builders (Claude, Codex, Cursor, Gemini, Grok, Kimi,
  OpenCode, Pi): default 300 seconds; explicit input remains supported.
- Hermes local UI builder: default 300 seconds, independently of max turns.
- Served UI builders for local adapters, generic/schema adapters, process,
  Hermes, HTTP, and OpenClaw match the policy. Ten assets in the current root
  bundle's reverse import closure use new `-timeouts-v2.js` URLs. Current HTML
  references those assets; earlier assets remain available for open tabs.

These are persisted Paperclip configuration defaults. Each adapter remains
responsible for enforcing its timeout field; provider-managed cloud execution
may have separate controls. Codex, OpenCode, process, HTTP, and both Hermes
execution paths read the configured limit. No provider or security settings
were changed.

## Verification and rollback

JavaScript syntax checks passed for all 26 changed/created files. Bounded
checks of the creation helper and native UI builders verified defaults,
explicit overrides, zero limits, and unrelated-field preservation. No real
agents were created for testing. Hash comparisons confirmed that all nine
existing adapter configurations stayed identical.

Paperclip restarted at 06:21:42 UTC after two checks found no live runs, and
returned `status=ok`, `authReady=true`, startup recovery `ready`. This was
completed before restoring Jarvis's separate CHI-43 recovery. No active worker
was restarted, and no gateway or Docker restart was needed.

Backups, pre-change agent config hashes, final file hashes, generated asset
mapping, the applied patch procedure, and reload result live outside Git:

`/data/paperclip/operator-backups/agent-timeout-policy-20261008T061940Z/`

For rollback, inspect `manifest.json`, verify the active payload and current
hashes, then restore only `existed=true` entries from `files/<path>`. Remove
the new helper only after restoring its import/call site. Restore HTML before
retiring generated assets. No agent database rollback is needed because no
existing config was changed. Restart only Paperclip during an idle window and
verify readiness. Upgrades require comparing and carrying forward this policy
alongside the previous Bubblewrap and Codex catalog patches.
