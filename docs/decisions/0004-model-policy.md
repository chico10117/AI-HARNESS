# 0004 — Model policy: free Muse 1.3 by default in OpenCode

- Date: 2026-10-05 · Status: **accepted (standing policy)**
- Context: Operator directive — OpenCode usage should prioritize the free
  Muse 1.3 tier (the tier this organization was bootstrapped with), keeping
  routine implementation work at zero marginal model cost.
- Decision:
  - `builder-vps` / `builder-debian` (OpenCode) default to the free Muse 1.3
    tier for bounded implementation, tests, refactors, docs, and research.
  - Escalate to a paid/frontier model only when the task demonstrably needs
    it (architecture, security-sensitive changes, failed free-tier attempts
    with a clear capability gap) — and that escalation is a cost decision
    the board (human) can audit via Paperclip budgets.
  - CTO/reviewer roles stay on capable models; never economize on review of
    security-sensitive or production-impacting changes.
- Consequences:
  - M2/M4 worker configs must pin the default model accordingly and expose
    per-agent spend so Paperclip budget hard-stops stay meaningful even when
    most runs cost nothing.
  - "Free by default" does not override quality gates: accepted work is the
    metric, not raw cost (spec principle 8).
