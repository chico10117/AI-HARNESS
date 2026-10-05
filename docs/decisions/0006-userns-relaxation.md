# 0006 — Relax AppArmor unprivileged-userns restriction for worker sandboxing

- Date: 2026-10-05 · Status: **accepted, applied and verified**
- Context: Codex workers (`codex_local`, Bubblewrap confinement) failed as
  user `paperclip` with `bwrap: loopback: Failed RTM_NEWADDR`, while
  `kernel.unprivileged_userns_clone=1`. Root cause: Ubuntu 24.04's
  `kernel.apparmor_restrict_unprivileged_userns=1` blocks unprivileged
  userns creation at the AppArmor layer.
- Decision: set `kernel.apparmor_restrict_unprivileged_userns=0`, persisted
  in `/etc/sysctl.d/99-paperclip-userns.conf` on recoVPS. Verified live +
  full bwrap bind test as `paperclip` passes.
- Consequences / trade-off (accepted): any local process can now create
  user namespaces (the default on most distros, but a relaxation vs. Ubuntu
  hardening). Mitigations: single-purpose worker host, workers run as
  unprivileged service users, sandboxing itself stays ON (bypass=false).
- Rollback (one line + delete file):
  `sysctl -w kernel.apparmor_restrict_unprivileged_userns=1` and remove
  `/etc/sysctl.d/99-paperclip-userns.conf`.
