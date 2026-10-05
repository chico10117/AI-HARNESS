# 0003 — SSH aliases: current names now, canonical names on tailnet

- Date: 2026-10-05 · Status: **done (both phases, verified 2026-10-05)**
- Context: Spec examples (`ai-vps`, `ai-debian`) don't exist. Real aliases:
  `recoVPS` (root, internet), `chiko_razer` (chiko, LAN). Operator chose
  "keep as-is" for aliases.
- Decision:
  - Phase 1 (now): keep using `recoVPS` / `chiko_razer` everywhere,
    including `scripts/health/`.
  - Phase 2 (once decision 0002 lands): add canonical `ai-vps` /
    `ai-debian` blocks in local `~/.ssh/config` pointing at tailnet names,
    keep old aliases as fallback until verified, then migrate scripts.
- Consequences: no broken-config risk during rollout; inventory tracks both
  names (`config/nodes/inventory.yaml`).
