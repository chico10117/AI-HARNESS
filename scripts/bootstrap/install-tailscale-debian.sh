#!/bin/sh
# Idempotent Tailscale installer for the Debian node (decision 0002).
# HUMAN-RUN: needs sudo (password). Run ON Debian, e.g.:
#   sh scripts/bootstrap/install-tailscale-debian.sh
# Safe to re-run: skips install when `tailscale` already exists.
# Does NOT log in: run `sudo tailscale up` (or with --auth-key) after, then
# verify from the Mac with scripts/health/check-debian.sh.
set -e
if command -v tailscale >/dev/null 2>&1; then
  echo "tailscale already installed: $(tailscale version | head -1)"
  echo "next: sudo tailscale up"
  exit 0
fi
echo "installing tailscale (official installer, requires sudo)..."
curl -fsSL https://tailscale.com/install.sh | sh
echo "installed: $(tailscale version | head -1)"
echo "next: sudo tailscale up   (interactive login in browser)"
