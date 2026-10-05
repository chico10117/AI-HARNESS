# Architecture

Source spec: `AGENTS-1st-launch.md`. This file records what was **discovered
(M0, 2026-10-05)** versus the **target**.

## Discovered topology (M0, verified via read-only SSH)

```text
                    HUMAN / BOARD
                           |
                Mac operator console (not 24/7)
                macOS 26.6.2 arm64
                codex-cli 0.160.0 · opencode 1.18.34
                Docker client 29.4.0 (OrbStack daemon DOWN)
                Tailscale 1.102.4 LOGGED OUT
                           |
            +--------------+---------------+
            | internet, SSH as root        | LAN, SSH as chiko
            v                              v
  recoVPS                            chiko_razer (hostname: debian)
  Ubuntu 24.04.4 LTS, up 234d        Debian 12 bookworm, up 10d
  4 vCPU / 7.6 GiB RAM               12 threads / 15 GiB RAM
  root disk 38G @ 80% (7.3G free)    root disk 91G @ 79% (19G free)
  /data 49G @ 35%                    swap 976M (427M used)
  ----------------                   ----------------
  OpenClaw 2026.9.7 gateway LIVE     Hermes gateway ACTIVE
    (user `openclaw`, node v24.21.0,   (user systemd unit, Telegram
     127.0.0.1:18789, /health ok)      polling connected, ~1.8G RSS)
  codex-cli 0.160.0                  codex-cli 0.160.0
  opencode 1.18.21                   opencode BROKEN (symlink -> /root/...)
  node v22.23.2, Docker 29.3.0       node v22.23.2, Docker 29.8.1 (no containers)
  pm2-root enabled, UFW active       no Tailscale installed
  Tailscale 1.102.4 LOGGED OUT       VPS->here: unreachable (NAT)
  Docker: traefik, reco-bot,
    node-service, postgres:16
  Paperclip: ABSENT                  Paperclip: ABSENT
```

Observed strays on VPS (2026-10-05): `codex --yolo` (root, 25+ days,
tmux `codex_todebug_opemclaw`) and `codex resume --last` (root, 4 days,
tmux `x402`, cwd `/data/side_projects/basepay-readiness-service`).
OpenClaw-spawned Codex app-servers under user `openclaw` (ephemeral creds)
are expected, not strays.

## Target topology (from spec)

Mac operates; durable Paperclip control plane lives on the always-on VPS,
isolated from OpenClaw (separate user/container, config, secrets, units);
Debian hosts Hermes persistently. One Codex + one OpenCode worker per node,
max 2 active compute-heavy workers per node.

## Network paths

| Path | Today | Target (tailnet decision 0002) |
|---|---|---|
| Mac -> VPS | direct SSH (internet) | unchanged + tailnet |
| Mac -> Debian | LAN SSH only (no travel access) | tailnet (works while traveling) |
| VPS -> Debian | impossible (NAT, verified) | tailnet direct |
| Debian -> VPS | port 22 open (internet) | tailnet preferred |

No private overlay is active today (Tailscale logged out / not installed).
Decision 0002 adopts a tailnet on all nodes; Section "Tailscale rollout"
tracks it. No SSH/RDP/VNC is to be exposed to the public Internet for
convenience.

Path roles with NordVPN active on the Mac (verified 2026-10-05): tailnet TCP
originated on the Mac dies in the double tunnel (both `ai-*` time out; also
MagicDNS doesn't resolve under Nord DNS) — use `mesh-debian` for Mac→Debian
and `recoVPS` (internet) for Mac→VPS. Tailnet paths (`ai-*`, VPS→Debian)
are for VPN-off/travel-off use and server-to-server traffic.

## Initial agent mapping (planned, none created)

| Agent | Runtime | Node | Role |
|---|---|---|---|
| `chief-of-staff` | Hermes | Debian | strategy, memory, coordination |
| `ops` | OpenClaw | VPS | integrations, scheduled work |
| `cto` | Codex CLI | Debian | architecture, review |
| `backend-infra` | Codex CLI | VPS | implementation, infra |
| `builder-debian` | OpenCode | Debian | bounded coding tasks |
| `builder-vps` | OpenCode | VPS | bounded coding tasks |
