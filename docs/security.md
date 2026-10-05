# Security

## Secrets — never commit

API keys, OAuth tokens, cookies/session tokens, SSH private keys, Paperclip
agent tokens, Hermes API keys, OpenClaw credentials, model-provider
credentials, Tailscale auth keys, production `.env` files.

Rules:

- Commit `.env.example` (names only). Never real values.
- Secrets are injected via service-manager environment, file bindings with
  `0600` ownership by the service user, or Paperclip secret references —
  never plaintext in Git, logs, task comments, or screenshots.
- Tailscale auth keys are one-shot bootstrap secrets: generated in the admin
  console, used once via `tailscale up --auth-key=...`, then expired/revoked.
  Prefer the console's expiry + tagging options. Never paste them into this
  repo or shared chat history.
- Scope least-privilege: agents receive only the credentials/paths/commands
  their role needs. Production/financial credentials never go to `ops`.

## SSH

- Use host aliases (`recoVPS`, `chiko_razer`; canonical `ai-vps`/`ai-debian`
  once the tailnet lands — see decision 0003). Prefer aliases over raw IPs.
- Keys, not passwords. No private keys in Git. No global
  `StrictHostKeyChecking=no`.
- VPS operates as `root` today (gap). M2 migrates Paperclip and workers to
  dedicated users (`paperclip`, `agent-worker`); `sudo` only for the specific
  command that needs it.
- Debian access is LAN-only today; travel access goes over the tailnet
  (decision 0002), never a router port-forward.

## Isolation

Distinct runtime identity per persistent service (`paperclip`, `openclaw`,
`hermes`, `agent-worker`). Workers never inherit the operator's `$HOME`,
`~/.ssh`, browser profile, or cloud credentials. One worker, one workspace:
no two coding agents in the same checkout (isolated clones/worktrees).

## Approval gates (binding, from spec)

Stop and get explicit human approval before: spending money; billing/payment
changes; new public exposure; DNS/cert/firewall/VPN changes; production
auth changes; reading/copying secrets beyond task minimum; deleting persistent
data/backups/repos; destructive migrations; external messages as the company;
first production deploy; security-model changes; disabling logging/monitoring/
backups/approvals/sandboxing. Read-only inspection never needs approval.

Breaking-change watch: Paperclip `v2026.1001.0` defaults execution
harnesses to full auto (Codex approval+sandbox bypass). Our M2 deploy must
set explicit restrictive modes so the gates above stay real (decision 0001).
