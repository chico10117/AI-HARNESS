# AI-HARNESS

Infrastructure and operating layer for a small, secure, multi-machine AI
organization coordinated by **Paperclip** (control plane / source of truth).

Spec: [`AGENTS-1st-launch.md`](AGENTS-1st-launch.md) — read it first.
Topology, roles, and change discipline all come from there.

## Current state (M0 inventoried 2026-10-05, M1 in progress)

| Node | Access (Mac) | Role |
|---|---|---|
| `recoVPS` — Ubuntu 24.04, always on | SSH as `root` (internet) | Paperclip host (planned), OpenClaw gateway (live), Codex + OpenCode workers (planned) |
| `chiko_razer` ("debian") — Debian 12, always on | SSH as `chiko` (LAN today, tailnet pending) | Hermes gateway (live), Codex + OpenCode workers (planned) |
| Mac | operator console | Browser + SSH, not a 24/7 node |

Paperclip is not installed anywhere yet. Target: `paperclipai/paperclip v2026.1001.0`
(see `docs/decisions/0001-paperclip-version.md`).

Model policy: OpenCode workers default to the free Muse 1.3 tier
(see `docs/decisions/0004-model-policy.md`).

## Layout

```text
.
├── AGENTS-1st-launch.md   # mission + operating spec (source of truth for how we work)
├── README.md
├── docs/
│   ├── architecture.md    # discovered + target topology
│   ├── security.md        # secrets, SSH, isolation, approval gates
│   └── decisions/         # architectural decision records
├── config/
│   └── nodes/
│       └── inventory.yaml # non-secret node capabilities (no credentials, no IPs)
├── scripts/
│   ├── bootstrap/         # idempotent setup scripts (human-run where sudo/login needed)
│   └── health/            # read-only checks per node
└── .env.example           # variable names only — never real values
```

## Quickstart (read-only)

```sh
scripts/health/check-mac.sh
scripts/health/check-vps.sh      # via SSH alias recoVPS
scripts/health/check-debian.sh   # via SSH alias chiko_razer
```

## Change discipline

- **L0 read-only**: proceed (health scripts, inspection).
- **L1 local reversible**: proceed (this repo's files).
- **L2 host config** (packages, users, systemd, tailnet): show plan, get approval first.
- **L3 production/external/irreversible**: explicit human approval, mandatory.

See `AGENTS-1st-launch.md` (approval gates) and `docs/security.md`.
