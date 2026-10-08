# 0009 — Paperclip 2026.1001.0 → 2026.1005.0 upgrade ATTEMPTED, auto-rolled back; ops claim DEFERRED

- Date: 2026-10-07 · Status: **attempted, rolled back (service healthy on 2026.1001.0)**
- Context: operator-authorized two-phase mission on recoVPS — Phase 1 upgrade
  Paperclip stable `2026.1001.0` → `v2026.1005.0` (stable channel confirms
  `2026.1005.0` as current stable; install was on `pinned` channel so
  `update --check` reported "current" and the exact-version flag was required).
  Phase 2 (ops invite→claim + write-back probe) gated on Phase 1 ending healthy.
- Install (sanctioned path determined, no reinstall):
  - Managed npm install: `~/.paperclip/cli/current -> installs/npm/2026.1001.0`,
    `install.json` (`source=npm`, `channel=pinned`). Data root symlinked:
    `~/.paperclip/instances -> /data/paperclip/instances`. Embedded postgres
    on 54329. Supervisor: systemd user unit `paperclipai.service` (linger on),
    API/UI on tailnet `100.73.61.81:3100`, `authenticated/private` mode.
  - Sanctioned upgrade path used: `paperclipai update --version 2026.1005.0`
    (`--dry-run` first: "Would update 2026.1001.0 → 2026.1005.0 after a
    database backup"). CLI performs its own pre-update `db:backup` automatically.
- Backup (verified BEFORE upgrade; no upgrade ran without one):
  - Explicit `db:backup`: `/data/paperclip/instances/default/data/backups/
    paperclip-20261007-171857.sql.gz` (2,401,669 bytes, `gzip -t` OK).
  - Updater's own pre-update backup: `paperclip-20261007-171934.sql.gz`
    (2,400,171 bytes) — also retained. Hourly auto-backups continue (latest
    pre-attempt `paperclip-20261007-165514.sql.gz`).
  - Company markdown export (80 files, all 8 agent dirs):
    `/tmp/paperclip-company-export-pre1005` (scratch, on VPS).
  - No secret values handled at any point; refs/IDs only.
- Upgrade outcome: **FAILED service validation, auto-rolled back.**
  - `2026.1005.0` payload downloaded to `installs/npm/2026.1005.0` (retained;
    `install.json.previous[0]` records it for `--rollback` use). `current`
    symlink restored to `2026.1001.0`. CLI message: "Updated payload failed
    service validation and was rolled back to 2026.1001.0, but the rolled-back
    service also failed to restart." — the last clause proved transient:
    `service status` + `health` confirm the rolled-back service IS active
    (pid 2343884, `processStartedAt 2026-10-07T15:22:01Z`, `phase=ready`).
  - Migrations 0284–0293: **APPLIED to the live DB by the 1005.0 startup**
    before validation failed (`Applying 10 pending migrations … 0284_petite_
    genesis … 0289_drop_user_keyboard_shortcuts … 0293_broad_rattler`, then
    `Migrations applied (pending migrations)`; server bound 3100 and finished
    startup recovery on 1005.0 at 17:20:54). The rolled-back 1001.0 binary
    reports `Migrations already applied` and runs healthy on the migrated
    schema. Split state: **binary 1001.0 / schema 1005.0** — recorded so a
    retry starts with zero pending migrations. No DB restore was needed
    (health never regressed), so pre-upgrade dumps were kept as insurance only.
  - Validation-failure root cause NOT established from available logs (service
    logs show a clean 1005.0 boot; updater-side validation detail is not
    surfaced). Prime suspect is updater health/validation timing after the
    hot-restart, not the migrations themselves. Do NOT retry blindly; diagnose
    updater validation (or vendor guidance) first.
- Post-rollback health (2026.1001.0, verified, no trials, no spend):
  - `auth whoami` ok (Chiko, instance admin, owner of `Chikocorp`
    `dd5f296e-…`). `health` ok, VPS-local UI `GET /api/health` → 200.
  - All 8 agents present, same ids/models/budgets/statuses (all `idle`):
    `builder-vps` + `builder-debian` (`opencode/muse-spark-1.3-contributor-free`,
    `dangerouslySkipPermissions=false` preserved); `cto` (`bypass=false`
    preserved); `backend-infra` (`deepseek-flash`, `bypass=false` preserved);
    `LOS Engineer` (`deepseek-flash`, `bypass=true` unchanged);
    `AI-Cofounder` (`bypass=true` unchanged); `ops` (`openclaw_gateway`,
    budget 5000, `idle`); `chief-of-staff` (`hermes_gateway`, budget 10000,
    `idle`). Read-only per-agent `get` confirmed for `ops` + `chief-of-staff`.
  - OpenClaw gateway `127.0.0.1:18789/health` → live. Mac→VPS tailnet direct
    UI check times out — EXPECTED, not a regression: NordVPN active on the Mac
    (double-tunnel kills Mac-originated tailnet TCP; see `architecture.md`
    §Network paths). Operator path remains internet SSH (`recoVPS`) + VPS-local.
  - Breaking-change verification for 1005.0 could NOT be performed (not running
    it): operator-UI snippets, always-on shortcuts, @-mentions no longer
    starting runs, full-auto harness defaults, and assignment-based coordination
    all remain UNVERIFIED against 1005.0 and must be re-checked on the retry.
- Phase 2 (ops claim + write-back probe): **NOT executed — explicitly deferred.**
  Gate was "only if Phase 1 ends healthy" (i.e. on 1005.0); the upgrade did not
  succeed, and mutating auth state (`invite→claim`, claimed key file) on a
  split binary/schema install would compound the failure. No invite created, no
  key file touched, no CHI-30 (or other) write performed. Re-arm Phase 2 only
  after a clean 1005.0 (or later) upgrade with healthy verification.
- Consequences / follow-ups (for operator):
  1. Decide: retry `update --version 2026.1005.0` (zero pending migrations now;
     may succeed if failure was timing) vs. hold on 1001.0/migrated-schema vs.
     await vendor fix. Recommend capturing updater validation criteria first.
  2. Terminated-agent husks (`f1d0d939`, `2101eb53`, per 0008) still present;
     `agent delete` 500s on 1001.0 — retry post-upgrade.
  3. Orphaned assignees CHI-2/CHI-19/CHI-20 + LOS instruction contradiction
     (per 0008 §follow-ups) unchanged; untouched by this attempt.
  4. Scratch artifacts on VPS: `/tmp/paperclip-company-export-pre1005`,
     retained `installs/npm/2026.1005.0` payload, pre-upgrade dumps — clean up
     or keep per operator preference.
  5. This file is UNCOMMITTED per mission constraints (`git status` shows only
     this new file alongside 0008); commit deliberately left to the operator.
