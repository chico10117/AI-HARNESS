# 0012 — paperclip-claimed-api-key.json restored, ops + Jarvis unblocked (VPS)

- Date: 2026-10-08 · Status: **applied, verified, committed**
- Mission: operator-ordered creation of the missing
  `~/.openclaw/workspace/paperclip-claimed-api-key.json`
  (real path `/data/openclaw/.openclaw/workspace/`, symlinked from
  `/home/openclaw/.openclaw/workspace/`) on recoVPS Paperclip
  `2026.1001.0`, company `dd5f296e-0ac2-4130-b181-03b1fe27dffa`.
- Auth: `auth whoami` = Chiko (owner, instance admin) via board key. Proceeded.

## Findings

- Neither `ops` (`df430bfb-04c6-4d3b-927d-7363e8f9323e`) nor `Jarvis`
  (`39a883fb-c862-43f7-bea8-e9380dbc7421`) sets `claimedApiKeyPath`
  (verified via `agent get --json` adapterConfig), so both use the shared
  default path. One shared file is correct.
- The invite `db5936b4-...` / join `ab4ed2fe-...` claim secret was ALREADY
  consumed at `2026-10-08T04:32:24Z` (HTTP 201, `claimSecretConsumedAt` set,
  key `initial-join-key` present). The token was stored only in
  `/home/openclaw/.local/share/paperclip-onboarding/jarvis-20261008/`
  (`claim-response.json`, mode 600), never copied to the workspace default
  path — that was the entire blockage. No re-claim possible (single-use).
- `ops` never had a join request and held zero agent API keys.

## Changes (all on recoVPS, no commits, no other agents touched)

1. Jarvis token: reused the sanctioned 04:32 claim (`initial-join-key`,
   keyId `97711f21-9479-4e95-a673-0230e1a5759b`, kind standard). No new key.
2. Ops token: minted ONE minimal-scope agent API key via admin CLI
   (`token agent create --agent ops --name ops-claimed`, kind standard),
   keyId `e79546ae-901d-46e8-849e-533c6964bca8`, `revokedAt=null`.
   A first minted key was revoked unused (keyId
   `f68b2e35-fa16-4ddc-8618-7dbef1f07dc4`, `revokedAt=2026-10-08T05:15:19Z`)
   after its value briefly appeared in local operator tooling output; it was
   never deployed anywhere. No secret values are recorded here.
3. Wrote shared file `/data/openclaw/.openclaw/workspace/
   paperclip-claimed-api-key.json` (visible at
   `/home/openclaw/.openclaw/workspace/paperclip-claimed-api-key.json`):
   JSON `{"version":1,"apiBaseUrl","companyId","agents":{"ops":{...},
   "jarvis":{...}}}` with each entry holding `agentId`/`keyId`/`token`.
   Owner `openclaw:openclaw`, mode `600`, 687 bytes. Built via root file-op
   only, merging the two source claim files without printing secrets.
4. Both tokens verified with `GET /api/agents/me` (correct id/name per agent).

## Smoke proof (no spend beyond API calls; no external pushes)

- ops: issue CHI-39 (`98f4728e-...`), run `a7b42d15-935f-4374-8f99-36330a4378b8`
  `succeeded`, exact comment `OK-SMOKE-OPS-2` posted via authenticated curl,
  issue `done`. No missing-file error (agent reported credential loaded).
- Jarvis: issue CHI-42 (`58f73b9f-a41a-419c-93a7-19bc95ff4e2f`), runs `fb867d1b-...` + `3f780a19-...` both `succeeded`,
  exact comment `OK-SMOKE-JARVIS-4` posted twice by agent
  `39a883fb-...`. No missing-file error (credential loaded, identity verified).
- Round-1 probes CHI-37 (ops) / CHI-38 (Jarvis) also show succeeded runs with
  agent-authored write-back and explicit credential-loaded statements.

## Remaining gaps

- Jarvis gateway sessions deny exec (`SYSTEM_RUN_DENIED` on curl): Jarvis can
  read the key file and write back via the runtime final-response channel but
  cannot run curl itself. `ops` sessions permit exec. If Jarvis needs direct
  HTTP write-back, the gateway operator must authorize exec for its sessions;
  out of scope for this mission.
- CHI-30/CHI-35/CHI-37/CHI-38/CHI-40/CHI-41 sit in `blocked`/`in_progress`
  with board-recovery notices from the smoke rounds; CHI-39 `done`, CHI-42 has
  the OK comments. Board may archive the scratch probes.
- Staging file `/tmp/ops-claim-new.json` shredded after use. Nothing committed.
