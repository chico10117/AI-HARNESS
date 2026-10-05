# 0002 — Private overlay: Tailscale on all nodes

- Date: 2026-10-05 · Status: **accepted, rollout in progress**
- Context: Debian is behind home NAT — VPS cannot reach it (verified 100%
  packet loss) and the laptop loses it while traveling. Tailscale was logged
  out on Mac/VPS and absent on Debian. Spec prefers a private overlay first.
- Decision: join all three nodes to one tailnet (Mac 1.102.4 present,
  VPS 1.102.4 present, Debian to be installed via `scripts/bootstrap/`).
  No router port-forwards, no publicly exposed SSH, ever, for this purpose.
- Consequences:
  - Stable tailnet names/IPs become the canonical addresses; travel access
    and VPS<->Debian reachability fall out of the same change.
  - Rollout needs human steps: `sudo` install on Debian + `tailscale up`
    login on each node (interactive URLs). Agent prepares, human executes,
    agent verifies.
  - Optional hardening later: tailnet ACLs limiting which node/user reaches
    which ports (least privilege).
