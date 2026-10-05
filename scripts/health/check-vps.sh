#!/bin/sh
# Read-only VPS health check over SSH alias recoVPS (L0). No changes.
set -u
ssh -o BatchMode=yes -o ConnectTimeout=10 recoVPS '
  echo "host=$(hostname) user=$(whoami) $(cat /etc/os-release 2>/dev/null | grep -m1 PRETTY_NAME)";
  uptime; free -h | head -2; df -h / /data | head -4;
  echo "--- runtimes ---";
  codex --version 2>&1 | head -1; opencode --version 2>&1 | head -1;
  echo "--- openclaw ---";
  curl -s -m 5 http://127.0.0.1:18789/health 2>&1 | head -c 200; echo;
  echo "--- paperclip (expect absent until M2) ---";
  command -v paperclip 2>&1 || echo "paperclip: absent";
  echo "--- tailscale ---";
  tailscale status 2>&1 | head -3;
'
