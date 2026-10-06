# Codex subscription auth — issue handoff

> Written 2026-10-06 after a long debug session. Read this to resume in a
> fresh terminal. Repo: `github.com/chico10117/AI-HARNESS` (private; several
> local commits unpushed — see §6).

## 1. Everything works EXCEPT Codex workers

| Part | State |
|---|---|
| Paperclip 2026.1001.0 on recoVPS (user `paperclip`, tailnet-only `100.73.61.81:3100`, telemetry off) | ✅ healthy |
| UI via Mac tunnel `http://127.0.0.1:13100` (LaunchAgent `com.aiharness.paperclip-tunnel`, persistent) | ✅ |
| Company Chikocorp + 8 agents (6 spec + operator's AI-Cofounder/LOS Engineer) | ✅ |
| Hermes → chief-of-staff (API `100.84.216.84:8642`, secret ref) | ✅ CHI-3 |
| OpenClaw → ops (loopback WS, pairing done) | ✅ runs OK; CHI-4 blocked by design (claimed credential) |
| OpenCode builders (model `opencode/muse-spark-1.3-contributor-free`) | ✅ builder-vps DONE (CHI-6); builder-debian PARTIAL (CHI-7 needs disposition click) |
| Tailnet (all nodes) + Meshnet Mac→Debian (`mesh-debian`, nft fix persisted via `meshnet-nft-fix.service`) | ✅ reboot-verified |
| **Codex workers `cto` + `backend-infra`** | ❌ **BLOCKED (this issue)** |

## 2. The stuck point, precisely

- UI shows a **Connected** OpenAI subscription ("Chiko's OpenAI").
- But Codex trials fail **pre-execution** with `configuration_incomplete` /
  *"Reconnect or validate the selected AI account"* — no spawn, no run-log.
- Server state: **two** OpenAI connections exist —
  `My OpenAI subscription / personal / isDefault=true / status=revoked` and
  two `OpenAI / shared / status=connected`. Workers use
  `responsible_user/subscription/openai`, which resolves to the **revoked
  personal default grant** (`37c31bc1`). The fresh Connect did NOT
  replace/re-bind it.
- Trial issues witnessing this: CHI-14, CHI-15, CHI-17 (all
  `configuration_incomplete`, 0¢). Earlier failures with different errors
  (bwrap bind, trusted-dir, 401 refresh) are all FIXED — do not re-debug.

## 3. Attempt history (do not repeat blindly)

1. bwrap `RTM_NEWADDR` → fixed via `kernel.apparmor_restrict_unprivileged_userns=0`
   (`/etc/sysctl.d/99-paperclip-userns.conf`, decision 0006).
2. bwrap `/bin`-before-`/usr` on merged-usr → local carry patch of
   `local-process-sandbox.js` (backup `.bak-20261005` alongside; decision
   0007 with diff + re-apply steps; watch upstream #10684 / PR #14178).
3. Codex 0.160 trusted-dir gate on local runs → `extraArgs:
   ["--skip-git-repo-check"]` on both agents (config-level, dedup-safe).
4. Token churn: many device logins each invalidated the last. Killed stray
   VPS refreshers (tmux `--yolo` + `resume`, 2 root app-server daemons —
   none were OpenClaw's). Browser has a single ChatGPT account.
5. Transplant of fresh local token into server secret (with backup) →
   proof run still failed → **rolled back** (v1 current again). Do not retry;
   the local copy was also dead server-side.
6. EACCES root cause found: Paperclip scaffolds session `log/`+`tmp/` as
   **root**; server (as `paperclip`) 500s on cleanup. Fix: `chown -R
   paperclip` each new session dir BEFORE running login.
7. codex 0.160 **ignores isolated `CODEX_HOME` for token storage** — device
   login always writes `/home/paperclip/.codex/auth.json`. The UI `/check`
   reads the session dir, so after each login you must
   `cp -a ~/.codex/auth.json <session>/auth.json` (0600, paperclip-owned)
   BEFORE clicking Connect. (Verified pattern 3×.)

## 4. Key technical facts

- Session dirs: `/home/paperclip/.paperclip/instances/default/ai-local-logins/<uuid>/`
- CLI admin pattern: `sudo -H -u paperclip bash -lc "export PATH=/opt/node-v24.21.0-linux-x64/bin:/home/paperclip/.local/bin:/usr/bin:/bin; export HOME=/home/paperclip XDG_RUNTIME_DIR=/run/user/1002; cd /tmp; paperclipai ..."` + `--api-base http://100.73.61.81:3100` (per-command flag; top-level flag unknown).
- Secret/grant IDs (metadata only): grant `37c31bc1`, old connection
  `57800dd4` (revoked), secret `c6c948a5` (v1 current, local_encrypted).
  Backups: `.../data/backups/paperclip-20261006-193730.sql.gz`,
  `/data/paperclip/secret-backup-2026-10-06T17-37-56-210Z.json` (0600).
- SSH: `recoVPS` (root/VPS), `mesh-debian` (chiko/Debian, VPN-proof),
  `chiko_razer` (LAN), `ai-*` (tailnet, VPN-off only). Mac→VPS always via
  `recoVPS`; NordVPN breaks Mac-originated tailnet TCP (see
  `docs/nordvpn-tailscale.md`).

## 5. Resume steps (in order)

1. In Paperclip UI, make the **healthy Connected subscription the default**
   for `responsible_user` (or re-validate/replace the revoked personal
   grant) — this is a UI/permission action, not CLI.
2. Verify: `cto` agent error clears (errorReason was "Reconnect or validate…").
3. Single trial: fresh issue for `cto` (marker+test, branch
   `agent/cto/m4-retry8-marker`), sequential, expect model events + 0¢.
   Then same for `backend-infra`. Then M4 is DONE → M5 end-to-end.
4. If it still fails identically: stop, capture exact error — do NOT start
   another device login (each one risks invalidating the last).

## 6. Current status + the fix that unblocked validation (2026-10-06 late)

**Cleanup done:** agent error flags cleared via sanctioned clear-error;
10 stale trial issues (CHI-5/8/9/10/11/12/13/14/15/17) moved to
`cancelled` with a proven NON-waking update (`issue update --status
cancelled`, no comment — commenting wakes agents). CHI-7/CHI-4
deliberately left blocked (need human disposition judgment).

**The fix for `configuration_incomplete`:** `cto` + `backend-infra` were
re-pointed from the revoked personal grant (`37c31bc1` / connection
`57800dd4`) to the healthy shared grant (`b0fd6a45` / connection
`1ea07e48` "Chiko's OpenAI") via partial agent update (all adapter fields
preserved). Validation gate now passes — runs spawn, confine, and reach
the model (`thread.started`).

**Still failing:** trials CHI-18/CHI-19 die with `refresh_token_invalidated`
(HTTP 401s on refresh) despite UI Connected. Conclusion: the shared
grant's stored token is ALSO dead — every device login so far produced
tokens OpenAI rejects at first refresh (single-account browser confirmed;
stray refreshers killed). Next: Reconnect the shared connection
(`1ea07e48`) in UI (or pick `c0806377`), then single fresh trial per
worker. If THAT still 401s, use the API-key escape hatch (real money).

## 7. Other pending items (not this issue)
- Push 8+ local commits to `github.com/chico10117/AI-HARNESS` (explicit `git push` never authorized yet).
- CHI-4 disposition (OpenClaw claimed credential), CHI-7 disposition click.
- 2 orphaned dummy secrets (`hermes_gateway.apikey.8f538c67…`, `…51c3b045…`, refs=0) await delete approval.
- Uncommitted work preserved at `/data/side_projects/basepay-readiness-service` (README, OPERATIONS, 3 HTML).
- Escape hatch if subscription keeps dying: workers on OpenAI API key
  billing instead of ChatGPT subscription (costs real money per token).
- global `~/.config/opencode/AGENTS.md`: background-subagent policy active;
  restart opencode sessions to pick up config changes.
