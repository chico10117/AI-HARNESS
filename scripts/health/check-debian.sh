#!/bin/sh
# Read-only Debian health check over SSH alias chiko_razer (L0). No changes.
set -u
ssh -o BatchMode=yes -o ConnectTimeout=10 chiko_razer '
  echo "host=$(hostname) user=$(whoami) $(cat /etc/os-release 2>/dev/null | grep -m1 PRETTY_NAME)";
  uptime; free -h | head -2; df -h / | head -3;
  echo "--- runtimes ---";
  codex --version 2>&1 | head -1;
  command -v opencode >/dev/null 2>&1 && opencode --version 2>&1 | head -1 || echo "opencode: BROKEN/MISSING (see inventory)";
  echo "--- hermes ---";
  systemctl --user is-active hermes-gateway 2>&1;
  echo "--- paperclip (expect absent until M2) ---";
  command -v paperclip 2>&1 || echo "paperclip: absent";
  echo "--- tailscale (expect absent until decision 0002 lands) ---";
  command -v tailscale 2>&1 || echo "tailscale: absent";
'
