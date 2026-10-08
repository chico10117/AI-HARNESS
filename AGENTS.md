# Working in AI-HARNESS

This repository documents and operates a small AI organization coordinated by
Paperclip. Paperclip owns goals, issues, assignments, approvals, budgets, and run
history. Hermes, OpenClaw, Codex CLI, and OpenCode execute that work. Keep task
state in Paperclip; do not add a competing scheduler or task database.

This is an infrastructure and documentation repository, not the Paperclip
application source. Editing this checkout does not change the installed server.

## Start here

1. Read this file, inspect `git status`, and identify the current host and user.
2. Read [AGENTS-1st-launch.md](AGENTS-1st-launch.md) for the original mission and
   operating principles, then the relevant [decision records](docs/decisions/).
3. Inspect the live installation before proposing runtime changes. The snapshot
   below was verified on the VPS on **2026-10-08** and can change.
4. Preserve existing services and unrelated work. Make the smallest reversible
   change that completes the user's request, then verify and document it.

Explicit user instructions and authorization take precedence. This file is the
current repository entry point. The README, architecture document, inventory,
health scripts, and Codex auth handoff contain older bootstrap facts, including
claims that Paperclip is absent, there are only eight agents, or Codex auth is
still blocked. Do not reinstall or repeat M0 because of those statements. Use
live inspection for current facts and newer decisions for change history; live
settings do not grant permission to change security policy.

## Verified VPS installation

| Item | Current state |
| --- | --- |
| Host | `recoVPS`, Ubuntu 24.04.4 LTS; operator shell is root |
| Service identity | Dedicated Unix user `paperclip` (UID 1002), home `/home/paperclip` |
| Paperclip | Managed npm install, **2026.1001.0**, pinned channel |
| CLI | `/home/paperclip/.local/bin/paperclipai`; not a globally installed `paperclip` binary |
| Payload | `/home/paperclip/.paperclip/cli/current` points to `cli/installs/npm/2026.1001.0` |
| Node runtime | `/opt/node-v24.21.0-linux-x64/bin/node` (managed CLI shim selects it) |
| Supervisor | Enabled systemd **user** unit `paperclipai.service`; `Linger=yes`, `Restart=always` |
| Unit file | `/home/paperclip/.config/systemd/user/paperclipai.service` |
| Persistent state | `/home/paperclip/.paperclip/instances` is a symlink to `/data/paperclip/instances` |
| Instance/config | `default`; `/home/paperclip/.paperclip/instances/default/config.json` |
| API/UI | Port **3100**, bound to the VPS Tailnet address; authenticated/private mode |
| Database | Embedded PostgreSQL, loopback-only port **54329**, instance `db/` directory |
| Logs | Instance `logs/` directory and the user service journal |
| Backups | Instance `data/backups/`; enabled every 60 minutes, 30-day retention |
| Assets/secrets | Local disk storage; `local_encrypted` secrets; service-owned `.env` is mode `0600` |
| Telemetry | Disabled |

Read-only checks returned service active/running, API `status=ok`,
`authReady=true`, startup recovery `ready`, and backup status `ok`. These checks
do not establish that every worker can execute tools or that restore is tested.
Sign-up is not disabled and secret strict mode is off in the observed config;
authenticated/private mode does not imply those controls are enabled.

The 2026.1005.0 upgrade attempt rolled the payload back after service validation
failed. [Decision 0009](docs/decisions/0009-paperclip-1005-upgrade-attempt.md)
records that its database migrations remained applied: **1001.0 binary with
1005.0 schema changes**. This schema history was not independently rechecked in
this inspection. The retained 1005.0 payload is not the running version. Diagnose
the validation failure before another upgrade; do not restore or migrate the
database merely to make version labels match.

## Network and neighboring services

- Mac is the operator console. Its documented Paperclip access is
  `http://127.0.0.1:13100` through the SSH tunnel managed by
  `com.aiharness.paperclip-tunnel`, using `recoVPS` over internet SSH.
- NordVPN on the Mac previously broke Mac-originated Tailnet TCP and MagicDNS.
  Use `mesh-debian` for Mac-to-Debian access; VPS-to-Debian uses Tailscale.
  See [the network notes](docs/nordvpn-tailscale.md). Mac and Debian were not
  directly inspected for this snapshot; verify their local aliases before use.
- OpenClaw runs as `openclaw`, separately from Paperclip, under user unit
  `openclaw-gateway.service`. Its loopback endpoint is
  `http://127.0.0.1:18789/health`; the check returned live.
- This VPS also serves production-adjacent Docker workloads. Containers seen
  running include `reco-bot`, `node-service`, `traefik`, and
  `basepay-live-stage-20260930`. Other workloads may exist: inspect before any
  host change. Never restart Docker or change shared networking as a shortcut
  for a Paperclip problem.

Prefer SSH aliases and discovered config over copying addresses into new files.
Do not expose Paperclip, PostgreSQL, or gateway admin endpoints publicly.

## Current company and agents

Company **Chikocorp**, ID `dd5f296e-0ac2-4130-b181-03b1fe27dffa`; issue prefix
`CHI`. Nine agents were present, idle, with healthy reporting chains; the
dashboard showed no running, paused, or errored agents and no pending approvals.

| Agent | Adapter/provider | Reports to |
| --- | --- | --- |
| `AI - Cofounder` | `codex_local`, OpenAI subscription; role `ceo` | Board/root |
| `Jarvis` | `openclaw_gateway`, VPS OpenClaw | AI - Cofounder |
| `LOS Engineer` | `codex_local`, DeepSeek `deepseek-flash` | AI - Cofounder |
| `chief-of-staff` | `hermes_gateway`, Debian Hermes | Board/root |
| `cto` | `codex_local`, OpenAI subscription; `gpt-5.6-sol` | chief-of-staff |
| `ops` | `openclaw_gateway`, VPS OpenClaw | chief-of-staff |
| `backend-infra` | `codex_local`, DeepSeek `deepseek-flash` | cto |
| `builder-vps` | `opencode_local`, `opencode/muse-spark-1.3-contributor-free` | cto |
| `builder-debian` | `opencode_local`, same free Muse model | cto |

Only the active **Local** execution environment was listed. Agent names such as
`builder-debian` do not select a remote node: current coding adapters are local
to the VPS unless a verified execution environment routes them elsewhere. The
original per-node placement remains a target, not proof of deployment.

`backend-infra` and `LOS Engineer` were recreated during migration. Resolve
current IDs by listing agents instead of reusing their terminated predecessors
from old notes. LOS instructions now mention DeepSeek; the earlier instruction
contradiction is resolved. Its configured cwd is a Paperclip project workspace,
not this checkout. Do not change agent instructions as a side effect of a repo
documentation task.

### Model, cost, and sandbox facts

- OpenCode builders default to the free Muse tier
  ([0004](docs/decisions/0004-model-policy.md)). Do not repeat the failed
  DeepSeek-through-OpenCode pilot. DeepSeek is provisioned through the two
  Codex agents' provider overrides and `DEEPSEEK_API_KEY` secret references.
- Paperclip recorded DeepSeek usage as `costCents=0` despite actual provider
  billing ([0008](docs/decisions/0008-deepseek-migration.md)). Paperclip budgets
  therefore do not reliably cap that spend; the operator manages it in the
  DeepSeek console. A zero displayed cost is not permission for more spend.
- Live `dangerouslyBypassApprovalsAndSandbox` values: **true** for `cto`,
  AI - Cofounder, and LOS Engineer; **false** for backend-infra. CTO's true
  value differs from older decision records. Both builders have
  `dangerouslySkipPermissions=false`. Record this drift; do not silently
  toggle these controls or assume all workers are confined.
- No Codex agent currently sets `filesystemScope`. CTO has no `networkScope`;
  both DeepSeek agents use a network allowlist. Reintroducing
  `filesystemScope=workspace` previously caused workspace-routing failures.
- CTO, backend-infra, and LOS Engineer include `--skip-git-repo-check`.
  Subscription refresh failures and the backend's `CHI-19` process-spawn fault
  are separate historical problems. A PONG response proves model access, not
  working shell tools. Confirm a fresh bounded tool test before claiming repair.

## Local patches and integration limits

- AppArmor user-namespace restriction is currently relaxed:
  `kernel.apparmor_restrict_unprivileged_userns=0`, persisted by
  `/etc/sysctl.d/99-paperclip-userns.conf`
  ([0006](docs/decisions/0006-userns-relaxation.md)).
- The installed `@paperclipai/adapter-utils/dist/local-process-sandbox.js`
  carries the merged-usr Bubblewrap patch, with `.bak-20261005` beside it
  ([0007](docs/decisions/0007-bwrap-mergedusr-patch.md)).
- The installed `@paperclipai/adapter-codex-local/dist/index.js` carries the
  `gpt-6.1-sol` catalog patch, with `.bak-20261008-060450` beside it
  ([0010](docs/decisions/0010-codex-local-add-gpt-6-1-sol.md)). The live catalog
  has 14 models including that entry; CTO remains pinned to `gpt-5.6-sol`.
- Both files live under the active payload's `node_modules`. An upgrade can
  overwrite these patches. Preserve backups and compare the new release before
  carrying a patch forward; follow each decision's validation and rollback steps.
- `ops` and Jarvis use the shared default claimed-credential file:
  `/home/openclaw/.openclaw/workspace/paperclip-claimed-api-key.json`, resolving
  into `/data/openclaw/.openclaw/workspace/`. Its owner is `openclaw`, mode
  `0600`; existence and permissions were checked without reading token values.
  [0012](docs/decisions/0012-paperclip-claimed-key.md) records successful
  identity/write-back probes. Do not re-claim consumed invites or rotate keys
  simply because an old issue says the file is missing.
- OpenClaw gateway runs do not automatically mount Paperclip's workspaces.
  Claimed credentials restore API identity, not filesystem access. Jarvis's
  gateway sessions previously denied exec (`SYSTEM_RUN_DENIED`) and used the
  final-response channel for write-back. Recheck capabilities before assigning
  file or shell validation; never open the whole Paperclip data tree to work
  around this limit.

## Safe read-only checks on this VPS

Run API commands as `paperclip` with its existing CLI auth. Avoid root-owned
Paperclip state and tokens in command arguments. This Bash helper discovers
the configured private address and does not print credentials:

```bash
PC_API_BASE="$(python3 - <<'PY'
import json
from pathlib import Path
config = json.loads(Path('/home/paperclip/.paperclip/instances/default/config.json').read_text())
server = config['server']
print(f"http://{server['host']}:{server['port']}")
PY
)"
PC_COMPANY_ID=dd5f296e-0ac2-4130-b181-03b1fe27dffa
pc_api() {
  sudo -H -u paperclip env XDG_RUNTIME_DIR="/run/user/$(id -u paperclip)" \
    /home/paperclip/.local/bin/paperclipai "$@" --api-base "$PC_API_BASE"
}
pc_api health
pc_api agent list -C "$PC_COMPANY_ID"
pc_api org get -C "$PC_COMPANY_ID"
pc_api dashboard get -C "$PC_COMPANY_ID"
pc_api adapter models codex_local -C "$PC_COMPANY_ID"
sudo -H -u paperclip env XDG_RUNTIME_DIR="/run/user/$(id -u paperclip)" \
  systemctl --user show paperclipai.service \
  -p ActiveState -p SubState -p UnitFileState -p MainPID -p NRestarts
curl --fail --silent --show-error --max-time 5 http://127.0.0.1:18789/health
df -h / /data
docker ps --format '{{.Names}}: {{.Status}}'
```

`--api-base` belongs on API subcommands, not at the CLI top level or on service
management commands. Inspect `--help` for the installed version before using
unfamiliar commands. For logs, use the `paperclip` user journal or instance log
directory, and redact before sharing; never dump environment files, CLI auth,
adapter credentials, or the encrypted-secret key. Agent JSON may contain sensitive
fields: select non-secret metadata before printing.

The health scripts in this repo are read-only SSH checks intended for the Mac;
their aliases and "expect absent" messages are historical. They are not an
accurate Paperclip service check on the VPS. There is no application test suite
or package manifest in this repo; documentation changes need diff/link checks,
and shell changes need syntax checks and appropriate bounded verification.

## Change and Git discipline

- Read-only discovery and reversible repository edits can proceed. Honor
  explicit authorization already given for the task; do not ask again for an
  approved commit or push.
- Host configuration, package installs, systemd changes, runtime restarts,
  authentication changes, migrations, and production changes need user
  authorization covering that action. Inspect first and prepare a concrete
  change before requesting any missing approval.
- Preserve the approval gates in [docs/security.md](docs/security.md): money,
  public exposure, DNS/firewall/VPN/security changes, destructive operations,
  and external communications require explicit authorization. Existing bypass
  flags do not waive these gates.
- Never commit or print real secrets, private keys, cookies, production `.env`
  files, claimed-agent JSON, OAuth tokens, or personal records. `.env.example`
  contains names only. Inspect only secrets required for the authorized task.
- One task has one owner; one coding worker has one isolated checkout. Use a
  dedicated branch/worktree, preserve unknown changes, and keep at most two
  active compute-heavy workers per Linux node. Do not delegate or launch agent
  runs merely to inspect the installation.
- Before an authorized upgrade, use the managed `paperclipai update` path as
  `paperclip`, take and verify a `paperclipai db:backup`, account for existing
  schema changes and local patches, then verify service, API, backups, and a
  bounded worker flow. Health alone does not prove restore or worker readiness.
- Assignment and comments can wake agents. Prefer read-only queries for
  discovery; do not create trials, reassign scratch issues, or post comments
  during an inspection. When working on an assigned Paperclip issue, leave
  results, verification, disposition, and a clear next action.
- Inspect remote and branch state before committing. Stage only intended
  files, run `git diff --check`, and verify the pushed commit. No force-push,
  hard reset, deletion of persistent state, or cleanup of another worker's
  worktree without authorization.
- If Git fails because a credential helper references the absent
  `/home/chiko/.local/bin/gh`, use the existing `/usr/bin/gh` login through a
  command-scoped helper override. Do not copy or display its token or change
  global Git auth as an incidental repair.
- Record durable infrastructure decisions in `docs/decisions/`; keep dated
  snapshots separate from policy. Report exactly what was verified and what
  remains untested.
