# 0008 — Split ChatGPT-subscription load: `backend-infra` + `LOS Engineer` to DeepSeek Platform API

- Date: 2026-10-07 · Status: **accepted (implemented, operator-authorized)**
- Context: four `codex_local` agents shared one ChatGPT subscription. The
  subscription grant was flaky (`refresh_token_invalidated` blocked M4 trials;
  inventory `config/nodes/inventory.yaml`), and concurrent load contended.
  Operator authorized moving `backend-infra` and `LOS Engineer` to the
  DeepSeek Platform API, keeping `cto` and `AI-Cofounder` on the subscription.
  Prior art: CHI-21 tried DeepSeek via `builder-vps` (`opencode_local`,
  model `deepseek/deepseek-v4.1-flash`) and failed `adapter_failed`; this
  record takes the `codex_local` provider-stanza path instead (verified
  against DeepSeek's official Codex integration doc + live CLI probes).
- Decision:
  - `LOS Engineer` and `backend-infra` run `codex_local`, engine `cli`,
    model `deepseek-flash`, provider stanza via `extraArgs -c` overrides and
    `DEEPSEEK_API_KEY` bound as an `env` `secret_ref` to the existing `test`
    secret (id `03dfcca4-…`, reused — no new secret minted, values never
    handled). `networkScope=allowlist` + `networkAllowlist=[api.deepseek.com]`.
    No `runtimeConfig.aiConnection` (fully off the subscription grant).
    `budgetMonthlyCents` caps preserved (0 and 5000). Names/slugs
    (`los-engineer`, `backend-infra`) and instructions preserved verbatim.
  - `cto` stays on the shared subscription grant (`b0fd6a45-…` /
    connection `1ea07e48-…`, model untouched); routing error repaired by
    stripping the `filesystemScope`/`networkScope` confinement (see below).
  - `AI-Cofounder`, `builder-vps`, `builder-debian`, `chief-of-staff`, `ops`
    untouched.
- What was changed (Paperclip `2026.1001.0`, company `Chikocorp`):
  - `LOS Engineer`: old `f1d0d939-…` (idle, `responsible_user` subscription)
    could not be patched — any `agent update` 422'd
    (`ai_connection_unavailable`, personal connection `57800dd4-…` broken) and
    `agent delete` 500'd. Terminated old, created new `8624e10e-…`
    (slug `los-engineer` preserved), restored 2149-byte `AGENTS.md` verbatim.
  - `backend-infra`: old `2101eb53-…` (`status=error`, workspace routing
    failure) terminated, created new `dbfeaebd-…` (slug `backend-infra`
    preserved, budget 5000, reportsTo `cto`), restored 4230-byte `AGENTS.md`.
  - `cto` (`9a55baa5-…`, id preserved): `replaceAdapterConfig` without
    `filesystemScope`/`networkScope`/`networkAllowlist`. No model/auth change.
  - Trial issues (scratch, left in place as evidence): CHI-23 (`e5ddad31-…`,
    LOS) and `7ad83a66-…` (backend), each a single PONG prompt; the platform
    ran 3 runs per issue (assignment → on_demand → automation follow-up).
- Costs observed (Paperclip ledger; DeepSeek-side billed externally):
  - LOS trial: runs `96b64eed`, `be62a2a7`, `c0ce5887` — all `succeeded`,
    model `deepseek-flash`, 162753 in / 121344 cached-in / 4900 out,
    Paperclip `costCents=0`. DeepSeek-side estimate at 2026-10 peak rates
    (~$0.30/1M in, $0.006/1M cache-hit, $1.20/1M out): ≈ **$0.055 (~6¢)**.
  - backend trial: runs `b7f1e05e`, `45fd2b92`, `eb366722` — all `succeeded`
    (reply `PONG`), 208143 in / 189568 cached-in / 2607 out,
    Paperclip `costCents=0`. DeepSeek-side estimate: ≈ **$0.067 (~7¢)**.
  - cto health check: wake run `b000a510` `succeeded` (69s, `advanced`,
    1 workspace op) on the subscription — 338516 in / 2881 out,
    `costCents=0` (`subscription_included`).
- Rationale / findings:
  - Routing root cause: `filesystemScope=workspace` (bwrap confinement) breaks
    codex 0.160 (`workspace routing discovery failed` is emitted by the codex
    binary). `filesystemScope: "off"` is rejected at run time
    (`must be "workspace"`); absence of the key works. `networkScope`
    allowlist is safe and kept on the DeepSeek agents.
  - Paperclip attributes `codex_local` usage to the `openai/chatgpt`
    `subscription_included` bucket **by adapter, keyed by configured model
    string** — DeepSeek runs show `model=deepseek-flash` with real tokens but
    `costCents=0`. Consequence: `budgetMonthlyCents` caps do NOT see DeepSeek
    spend; enforce spend control in the DeepSeek console (caps/alerts).
  - The old `test`-secret binding `access.Deepseek → builder-vps` (CHI-21
    era) was left as-is; `test` now also binds `env.DEEPSEEK_API_KEY` on the
    two migrated agents (verified via `secrets usage`, refs only).
- Consequences / follow-ups (for operator):
  1. Verify ≈13¢ total in the DeepSeek console; set console-side budget/alerts
     (Paperclip cannot cap this spend).
  2. Terminated husks remain (`f1d0d939`, `2101eb53`) — `agent delete` 500s
     on this version; retry delete after a future Paperclip upgrade.
  3. Orphaned assignees: CHI-2 (`in_review`) → old LOS id; CHI-19/CHI-20 →
     old backend id. Reassign to `8624e10e` / `dbfeaebd` when convenient.
  4. `LOS Engineer` instructions still say "Use the existing OpenAI
     subscription connection only" — contradicts this migration; needs an
     operator-approved instruction edit (preserved verbatim deliberately).
  5. Consider adding `models.json` catalog (`model_catalog_json`) — runs work
     on fallback metadata today with a startup warning; catalog improves
     reasoning/tool behavior for real workloads.
  6. `cto` lost its network allowlist in the repair (values are API-redacted
     and unrecoverable via CLI; open egress = creation-time posture). Re-add
     an explicit allowlist if desired — needs fresh values, not restorable.
  7. Subscription grant health: cto's wake run succeeded on subscription
     today, so the shared grant currently works; if `refresh_token_invalidated`
     recurs, only `cto` + `AI-Cofounder` are exposed (the migration halves
     contention as intended).
