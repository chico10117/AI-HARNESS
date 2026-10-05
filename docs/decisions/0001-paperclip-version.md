# 0001 — Paperclip version: v2026.1001.0

- Date: 2026-10-05 · Status: **accepted** (source/release pinned; not yet deployed)
- Context: M0 found Paperclip on no node. Spec requires recording the
  installed version before configuring adapters. Operator chose "use latest
  release".
- Decision: target upstream `paperclipai/paperclip` at release
  **`v2026.1001.0`** (published 2026-10-02; Node.js server + React UI,
  self-hosted, no account required).
- Consequences:
  - M2 must verify checksum / release-tag-pinned source at deploy time.
  - **Breaking change carved in:** execution harnesses default to full auto
    (Codex runs with approval-and-sandbox bypass unless configured
    otherwise). M2 must set explicit restrictive modes on every agent so
    our approval gates (`docs/security.md`) stay enforced.
  - Legacy Composio broker retired — irrelevant (never used here).
  - Adapter inventory (OpenClaw gateway, `codex_local`, `opencode_local`,
    `hermes_gateway`, `process`, `http`) to be verified against this exact
    version during M2/M3, not assumed.
