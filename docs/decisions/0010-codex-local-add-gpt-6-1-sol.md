# 0010 — Added `gpt-6.1-sol` to `codex_local` static model list (1001.0, VPS)

- Date: 2026-10-08 · Status: **applied, verified healthy (service restarted, no rollback needed)**
- Context: operator-approved mission — surface `gpt-6.1-sol` in the agent-edit
  model dropdown on the recoVPS Paperclip install (managed-npm `2026.1001.0`,
  `~/.paperclip/cli/current -> installs/npm/2026.1001.0`, supervisor: systemd
  user unit `paperclipai.service`, API `100.73.61.81:3100`). No commits.
- Template: retained `installs/npm/2026.1005.0` payload, which adds `gpt-6-sol`
  / `gpt-6-luna` (fast-mode + Sol→ultra efforts / Luna→max efforts). `gpt-6.1-sol`
  is Sol-tier ⇒ ultra effort range, fast-mode eligible.
- Backup (BEFORE edit, verified): `/home/paperclip/.paperclip/cli/installs/npm/
  2026.1001.0/node_modules/@paperclipai/adapter-codex-local/dist/index.js
  .bak-20261008-060450` (byte-identical copy alongside, `node --check` OK after).
- Exact diff (3 hunks, `dist/index.js` only; `DEFAULT_CODEX_LOCAL_MODEL`,
  aliases, docs, tests untouched):
  1. `CODEX_LOCAL_FAST_MODE_SUPPORTED_MODELS`: added `"gpt-6.1-sol"` after
     `"gpt-6-astra"`.
  2. `codexLocalReasoningEffortsForModel`: `gpt-6.1-sol` now returns
     `CODEX_LOCAL_ASTRA_REASONING_EFFORTS` (`[low,medium,high,xhigh,max,ultra]`,
     identical to the 1005 `ULTRA` list) alongside `gpt-6-astra`; all other
     models unchanged.
  3. `models`: added `{ id: "gpt-6.1-sol", label: "gpt-6.1-sol" }` after the
     `gpt-6-astra` entry (position 3).
- Restart: **YES, required.** `adapter models --refresh` still returned 13
  entries (list served from the long-lived server process, module cached since
  Oct 07). `systemctl --user restart paperclipai.service` → active/running
  (new pid 2527259). Heartbeat scheduler catches up; no agent trials run.
- Post-change verification:
  - `adapter models codex_local`: **14 entries**, `gpt-6.1-sol` present at
    position 3 (13+1 as expected). Full list: gpt-5.6-sol, gpt-6-astra,
    gpt-6.1-sol, gpt-5.6-terra, gpt-5.6-luna, gpt-5.4, gpt-5.4-mini, gpt-5,
    o3, o4-mini, gpt-5-mini, gpt-5-nano, o3-mini, codex-mini-latest.
  - Direct module check: `isCodexLocalKnownModel → true`,
    `isCodexLocalFastModeSupported → true`,
    `codexLocalReasoningEffortsForModel → [low,medium,high,xhigh,max,ultra]`;
    `gpt-6-astra` and `gpt-5.6-sol` efforts unchanged; default still `gpt-5.6-sol`.
  - `cto` effective model: **unchanged, no pin action needed.** Correction to
    mission brief: `cto` was already explicitly pinned (`adapterConfig.model =
    "gpt-5.6-sol"`, effort `high`), not unpinned — before AND after identical,
    status `idle`. No silent default shift possible (default untouched anyway).
  - Service health: `paperclipai.service` active/running; all 8 agents present
    with same ids/budgets (chief-of-staff briefly `running` = normal post-restart
    heartbeat catch-up).
- Rollback: **NOT used** (list updated, service healthy). Plan if ever needed:
  `cp <backup> index.js` + `systemctl --user restart paperclipai.service` +
  re-run `adapter models` (expect 13, no `gpt-6.1-sol`).
- Notes: `agentConfigurationDoc` strings still enumerate the old model sets
  (cosmetic, functional dropdown unaffected — left untouched per minimal-diff
  constraint). Bundled `index.test.js` expectations predate this change
  (not executed in prod). No secrets handled; no spend; no trials.
- This file is UNCOMMITTED per mission constraints; commit left to operator.
