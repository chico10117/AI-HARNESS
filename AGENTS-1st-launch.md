## Mission

Build and operate a small, secure, multi-machine AI organization coordinated by **Paperclip**.

Paperclip is the control plane and source of truth for company goals, agents, tasks, status, budgets, approvals, and run history. Individual runtimes such as Hermes, OpenClaw, Codex CLI, and OpenCode are execution engines underneath Paperclip; they must not become competing task-management systems.

This repository is the infrastructure and operating layer for that organization.

---

## Target topology

```text
                           HUMAN / BOARD
                                |
                         Mac (operator)
                    Browser + Codex CLI + SSH
                                |
                     private network / SSH
                                |
              +-----------------+-----------------+
              |                                   |
              v                                   v
      Linux VPS (24/7)                    Debian laptop (24/7)
      ----------------                    --------------------
      Paperclip control plane             Hermes persistent agent
      OpenClaw gateway                    Hermes API/gateway
      Codex worker                        Codex worker
      OpenCode worker                     OpenCode worker
```

### Preferred placement

The Mac is an **operator console**, not a required 24/7 execution node.

Prefer running the durable Paperclip server/control plane on the always-on VPS and accessing its UI from the Mac. Keep Paperclip isolated from OpenClaw even when they share the same host: separate Unix users and/or containers, separate config directories, separate secrets, and separate service units.

If the installed Paperclip version or deployment constraints make this impractical, document the reason before changing the topology.

---

## Initial Paperclip organization

Start small. Do not create agents merely because capacity exists.

| Agent | Runtime | Primary node | Role |
|---|---|---|---|
| `chief-of-staff` | Hermes | Debian laptop | Strategy, decomposition, continuity, long-term memory, coordination |
| `ops` | OpenClaw | VPS | Operations, integrations, scheduled/event-driven work |
| `cto` | Codex CLI | Debian laptop | Architecture, technical decisions, code review |
| `backend-infra` | Codex CLI | VPS | Implementation, backend, infrastructure, deployment work |
| `builder-debian` | OpenCode | Debian laptop | Bounded implementation, research, testing |
| `builder-vps` | OpenCode | VPS | Bounded implementation, scripting, testing |

Paperclip remains the authority for assignment and status even when Hermes or OpenClaw maintain their own internal memory.

### Default concurrency

Until measurements prove otherwise:

- Maximum **2 active compute-heavy workers per Linux node**.
- Resident Hermes/OpenClaw gateway processes do not count unless they are actively executing expensive work.
- Avoid running multiple heavy builds, local LLM inference, or large dependency installs concurrently on the same node.
- Increase concurrency only after measuring RAM, CPU, disk I/O, latency, failure rate, and token cost.

---

## Architectural principles

1. **Paperclip is the control plane.**
   - Goals, issues, ownership, task state, approvals, and budgets belong in Paperclip.
   - Do not implement a second scheduler unless Paperclip cannot represent a required workflow.

2. **Runtimes are replaceable workers.**
   - Hermes, OpenClaw, Codex CLI, and OpenCode are adapters/execution engines.
   - Do not tightly couple company logic to one model provider or harness.

3. **One task, one owner.**
   - Avoid two agents editing the same task or checkout simultaneously.
   - Parallelize by decomposing work into independent tasks.

4. **One worker, one workspace.**
   - Never let two coding agents write concurrently to the same Git checkout.
   - Use isolated clones, worktrees, containers, or Paperclip environments.

5. **Infrastructure must be reproducible.**
   - Prefer committed configuration, Docker Compose, systemd units, Ansible, or idempotent scripts over undocumented shell history.
   - A fresh machine should be recoverable from this repo plus secrets.

6. **Least privilege by default.**
   - Agents receive only the credentials, paths, commands, and network access required for their role.
   - Never give all agents the same production credentials.

7. **Human approval at irreversible boundaries.**
   - Autonomous work is encouraged inside bounded workspaces.
   - External or irreversible actions require explicit approval unless a later policy deliberately relaxes the gate.

8. **Measure before scaling.**
   - More agents are not automatically better.
   - Optimize for completed useful work per dollar and per hour, not agent count.

---

## Approval gates

An agent MUST stop and request explicit human approval before any of the following unless a narrower written policy in this repository explicitly permits it:

- spending money or initiating any financial/crypto transaction;
- modifying billing, payment, exchange, wallet, or banking settings;
- exposing a new service publicly to the Internet;
- changing DNS, domain ownership, certificates, firewall policy, or VPN topology;
- modifying authentication or authorization for production systems;
- reading or copying secrets outside the minimum scope required for its task;
- deleting persistent data, backups, repositories, cloud resources, or production databases;
- destructive or difficult-to-reverse migrations;
- sending external email/messages/posts as the company or operator;
- deploying to production for the first time;
- merging changes that alter the security model;
- disabling logging, monitoring, backups, approval controls, or sandboxing.

Routine read-only inspection does not require approval.

---

## Security model

### Network

Prefer this order:

1. private overlay/VPN between machines;
2. SSH-based Paperclip execution environments;
3. TLS-authenticated gateway/API connections;
4. public exposure only when strictly necessary.

Do not expose Hermes, OpenClaw, Paperclip admin APIs, SSH, databases, or raw agent endpoints to the public Internet merely for convenience.

### SSH

- Use host aliases from `~/.ssh/config`; do not commit IP addresses when an alias is sufficient.
- Prefer SSH keys, not passwords.
- Do not commit private keys.
- Do not disable host-key checking globally.
- Use a dedicated non-root automation user where practical.
- Escalate with `sudo` only for the specific command that needs it.

Example logical aliases:

```text
ai-vps
ai-debian
```

These are examples, not assumptions. Discover the actual configured aliases before using them.

### Secrets

Never commit:

- API keys;
- OAuth tokens;
- cookies/session tokens;
- SSH private keys;
- Paperclip agent tokens;
- Hermes API server keys;
- OpenClaw credentials;
- model-provider credentials;
- production `.env` files.

Commit `.env.example` files containing variable names only.

Secrets must be injected through an approved secret store, environment binding, service manager, or Paperclip secret reference.

Never print secrets in logs, task comments, pull requests, screenshots, or terminal summaries.

### Isolation

Prefer a distinct runtime identity for each persistent service:

```text
paperclip
openclaw
hermes
agent-worker
```

Exact names may differ.

Do not let an autonomous worker inherit unrestricted access to the operator's `$HOME`, `~/.ssh`, browser profile, password manager, cloud credentials, or unrelated repositories.

---

## Paperclip integration rules

Before configuring adapters, detect and record the installed Paperclip version. Do not assume every adapter or environment feature is present in every version.

### Hermes

The Debian laptop already hosts Hermes.

Preferred integration:

- keep Hermes running independently on the Debian laptop;
- expose its authenticated API only over the private network;
- connect Paperclip through the Hermes gateway adapter when supported;
- use HTTPS for non-loopback access unless the connection is protected by a private trusted transport;
- store the Hermes API key as a Paperclip secret reference, never plaintext in Git.

Do not replace the existing Hermes installation simply to make Paperclip integration easier.

### OpenClaw

The VPS already hosts OpenClaw.

Preferred integration:

- preserve the existing OpenClaw instance;
- use Paperclip's supported OpenClaw gateway/invite integration if available in the installed version;
- if the UI marks the gateway adapter unavailable, verify the documented API/invite path before inventing a workaround;
- do not patch Paperclip core solely to make OpenClaw connect.

OpenClaw should primarily handle operations, integrations, event-driven actions, and communication-oriented workflows.

### Codex CLI

Codex workers may run:

- locally on the Paperclip host; or
- on a Paperclip SSH execution environment when supported by the installed version.

Each Codex agent must have:

- its own Paperclip identity;
- its own managed Codex state/home where supported;
- an isolated Git workspace;
- a bounded working directory;
- explicit environment variables/secrets;
- a defined role.

Do not make a Codex worker use the operator's entire home directory as its workspace.

### OpenCode

Treat OpenCode as a provider-flexible implementation worker.

Use it for:

- bounded coding tasks;
- repetitive implementation;
- tests;
- refactors;
- lower-cost tasks where a frontier model is unnecessary.

Keep architecture, security-sensitive changes, and final review assigned to the appropriate reviewer/CTO role.

---

## Repository structure

Prefer the following shape unless the existing repository already establishes a better convention:

```text
.
├── AGENTS.md
├── README.md
├── docs/
│   ├── architecture.md
│   ├── operations.md
│   ├── security.md
│   └── decisions/
├── config/
│   ├── agents/
│   ├── nodes/
│   └── paperclip/
├── infra/
│   ├── ansible/
│   ├── compose/
│   └── systemd/
├── scripts/
│   ├── bootstrap/
│   ├── health/
│   └── maintenance/
├── tests/
└── .env.example
```

Do not create empty directories just to satisfy this diagram. Add structure as the implementation requires it.

---

## Node inventory

Maintain a non-secret inventory describing capabilities, not credentials.

Example:

```yaml
nodes:
  vps:
    ssh_alias: ai-vps
    always_on: true
    services:
      - paperclip
      - openclaw
    worker_capacity: 2

  debian:
    ssh_alias: ai-debian
    always_on: true
    services:
      - hermes
    worker_capacity: 2
```

The real inventory may include CPU/RAM/GPU/disk capabilities, installed runtimes, and labels. Do not include passwords, API keys, raw private keys, or other secrets.

---

## Workspace and Git policy

For every coding task:

1. Start from a clean, synchronized base branch.
2. Create a dedicated branch.
3. Allocate a dedicated worktree or isolated clone to the worker.
4. Make focused commits.
5. Run relevant tests, linting, and type checks.
6. Have a different role/model review security-sensitive or non-trivial changes.
7. Merge only after required checks pass.
8. Clean up abandoned worktrees after confirming no uncommitted work is present.

Recommended branch naming:

```text
agent/<agent-name>/<task-id>-short-description
```

Never use `git reset --hard`, force-push, delete branches, or discard unknown uncommitted work unless explicitly approved.

Never modify another agent's active worktree.

---

## Task lifecycle

Paperclip should represent this lifecycle:

```text
goal
  -> project
    -> issue/task
      -> assigned worker
        -> implementation/research
          -> verification
            -> review
              -> approval when required
                -> done
```

Agents should update task state rather than silently working for long periods.

For significant work, the assignee should leave concise artifacts:

- what changed;
- files/services affected;
- tests or checks performed;
- unresolved risks;
- cost or resource anomalies;
- follow-up tasks.

---

## Role boundaries

### `chief-of-staff` / Hermes

Responsible for:

- turning company goals into projects/tasks;
- maintaining strategic continuity;
- identifying blockers/dependencies;
- summarizing progress;
- deciding which specialist should receive a task;
- maintaining durable operational knowledge.

Not the default coding worker.

Must not independently approve its own high-risk action.

### `ops` / OpenClaw

Responsible for:

- scheduled tasks;
- integrations;
- notifications;
- operational checks;
- bounded external workflows;
- routine service operations.

Must not receive unrestricted production or financial credentials.

### `cto` / Codex

Responsible for:

- architecture;
- technical decomposition;
- difficult debugging;
- security-sensitive review;
- reviewing other coding workers;
- deciding when an implementation needs a design record.

Avoid using this role for cheap repetitive work.

### `backend-infra` / Codex

Responsible for:

- backend implementation;
- deployment code;
- infrastructure;
- integration work;
- CI/CD changes;
- complex coding tasks.

Changes with production or security impact require independent review.

### `builder-*` / OpenCode

Responsible for:

- bounded implementation;
- tests;
- documentation;
- refactors;
- data transformations;
- routine research.

Do not assign unrestricted company-wide goals to builders.

---

## Observability

For every persistent service, establish at minimum:

- health check;
- structured or searchable logs;
- restart policy;
- disk-usage visibility;
- basic CPU/RAM monitoring;
- failure visibility;
- run/task correlation where possible.

For Paperclip agents, track:

- run count;
- task completion rate;
- retries;
- token/model cost where available;
- median task latency;
- failed runs;
- human interventions;
- review rejection/rework rate.

Do not optimize model cost in isolation. Optimize useful, accepted work.

---

## Service management

Persistent 24/7 services should run under a supervisor such as systemd or Docker Compose.

Avoid relying on:

- ad-hoc `tmux` sessions;
- shell windows;
- `nohup` without lifecycle management;
- undocumented manual startup commands.

Every persistent service should have a documented way to:

```text
start
stop
restart
status
view logs
backup
restore
upgrade
```

---

## Change discipline

Before making a change, classify it:

### Level 0 — read-only

Examples: inspect files, versions, logs, status.

Proceed autonomously.

### Level 1 — local reversible

Examples: create project files, install project-local dependencies, modify a feature branch.

Proceed autonomously unless existing repo instructions say otherwise.

### Level 2 — host configuration

Examples: install system packages, create users, modify systemd, change Docker daemon config, change firewall rules.

Show the intended change and obtain approval before executing it on a remote host.

### Level 3 — production/external/irreversible

Examples: DNS, production deploy, deletion, public exposure, secrets/auth changes, financial actions, external messages.

Explicit human approval is mandatory.

---

## Codex CLI operating instructions

When Codex CLI starts work in this repository:

1. Read this entire `AGENTS.md`.
2. Inspect `README.md`, `docs/`, existing infrastructure files, and repository status.
3. Run read-only discovery before proposing architecture changes.
4. Do not assume hostnames, usernames, ports, paths, Paperclip versions, or installed runtimes.
5. Detect what already exists before installing anything.
6. Preserve the existing OpenClaw VPS and Hermes Debian deployments.
7. Prefer extending working systems rather than rebuilding them.
8. Make the smallest reversible change that advances the current milestone.
9. Keep infrastructure changes idempotent.
10. Validate after each meaningful change.
11. Record important architectural decisions under `docs/decisions/`.
12. Never expose or commit secrets.
13. Never perform Level 2 or Level 3 changes without the required approval.
14. When blocked by missing information, collect all safe/read-only facts first, then ask one precise question.
15. Do not create unnecessary abstraction, orchestration layers, message buses, databases, or agent frameworks.

---

## Bootstrap milestones

Implement these in order. Do not jump ahead merely because later work is more interesting.

### M0 — Inventory

Produce a factual inventory of:

- repository state;
- Mac tooling required to operate the system;
- Paperclip version/deployment status;
- VPS OS/resources/services;
- Debian OS/resources/services;
- Hermes version and API/gateway capability;
- OpenClaw version and gateway capability;
- Codex CLI availability;
- OpenCode availability;
- network path between nodes;
- existing SSH aliases;
- existing service managers/containers.

This phase is read-only.

### M1 — Repository foundation

Create only what is needed:

- architecture documentation;
- node inventory;
- `.env.example`;
- bootstrap/health scripts;
- decision-record structure;
- secret-handling documentation.

No production changes.

### M2 — Paperclip control plane

Deploy/configure Paperclip on the preferred always-on node.

Requirements:

- authenticated or private deployment mode when network reachable;
- persistent data;
- backups;
- service supervision;
- no unnecessary public exposure;
- UI reachable from the Mac through the approved private path.

### M3 — Existing persistent agents

Connect, do not replace:

1. Hermes on Debian.
2. OpenClaw on VPS.

Test a harmless read-only task through each integration.

### M4 — Coding workers

Add:

- one Codex worker on VPS;
- one Codex worker on Debian;
- one OpenCode worker on VPS;
- one OpenCode worker on Debian.

Use isolated workspaces and a maximum of two active compute workers per node.

### M5 — End-to-end workflow

Create a disposable test repository/task and prove:

```text
Paperclip
 -> assign
 -> worker executes
 -> task status updates
 -> code/artifact produced
 -> reviewer checks it
 -> result is accepted/rejected
 -> logs and costs are visible
```

No production repository should be the first test.

### M6 — Guardrails and recovery

Verify:

- service restart behavior;
- agent timeout/retry behavior;
- workspace cleanup;
- credential revocation;
- backup and restore;
- failed-task handling;
- runaway-agent stop procedure;
- host disk exhaustion protection.

### M7 — First real project

Only after M0-M6 work reliably, onboard one real software project.

Start with a small bounded project before attempting a continuously autonomous startup.

---

## Definition of done for the first phase

The initial platform is ready when all of the following are true:

- Paperclip is reachable securely from the Mac.
- VPS and Debian nodes are represented as execution targets or documented integrations.
- Existing OpenClaw and Hermes installations remain functional.
- Paperclip can successfully assign work to Hermes.
- Paperclip can successfully assign work to OpenClaw through a supported integration.
- At least one Codex worker can complete a coding task.
- At least one OpenCode worker can complete a coding task.
- Two workers cannot accidentally edit the same checkout.
- Secrets are not stored in Git.
- Services survive reboot.
- Logs make failed runs diagnosable.
- A human approval gate blocks high-risk actions.
- Backup/recovery steps are documented and tested.
- The end-to-end disposable test workflow passes.

---

## First task for Codex

Begin with **M0 — Inventory** only.

Do not install, upgrade, restart, reconfigure, expose, or delete anything yet.

Your first output should be:

1. a concise diagram of the discovered current architecture;
2. a table of versions/services/capabilities on each node;
3. connectivity and authentication assumptions that were verified vs. not verified;
4. gaps between the current state and this target architecture;
5. the smallest proposed M1 implementation plan;
6. any approvals or information required before M1.

Prefer commands that are read-only and safe.

The goal of the first run is **understanding the system, not changing it**.
"""

path = Path("/mnt/data/AGENTS.md")
path.write_text(content, encoding="utf-8")
print(f"Created {path} ({len(content.splitlines())} lines, {path.stat().st_size} bytes)")

