#!/bin/sh
# Read-only Mac operator health check (L0). No changes, no secrets printed.
set -u
ok=1
say() { printf '%s: %s\n' "$1" "$2"; }
say "sw_vers" "$(sw_vers -productVersion 2>/dev/null || echo MISSING)"
for t in codex opencode ssh tailscale docker; do
  if command -v "$t" >/dev/null 2>&1; then say "$t" "present ($(command -v "$t"))";
  else say "$t" "MISSING"; ok=0; fi
done
codex --version 2>&1 | head -1
opencode --version 2>&1 | head -1
tailscale status 2>&1 | head -3
docker ps --format '{{.Names}} {{.Status}}' 2>&1 | head -5
[ "$ok" -eq 1 ] && echo "MAC OK" || { echo "MAC ATTENTION"; exit 1; }
