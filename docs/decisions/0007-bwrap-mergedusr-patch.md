# 0007 — Local carry: bwrap merged-usr patch (tech debt)

- Date: 2026-10-06 · Status: **applied, pending upstream release**
- Context: Paperclip's sandbox builder bind-mounted `/bin` before `/usr`,
  fatal on merged-usr hosts (Ubuntu 24.04, Debian 12+). No config knob
  exists. Upstream: issue #10684, PR #14178 (draft) — no release contains it.
- Decision: carry the #14178-shaped hunk locally (option 1) until
  `paperclip update` ships it. Zero confinement change (same files visible).
- Applied to:
  `/home/paperclip/.paperclip/cli/installs/npm/2026.1001.0/node_modules/@paperclipai/adapter-utils/dist/local-process-sandbox.js`
  - backup: same path + `.bak-20261005` (19143 bytes, root-owned)
  - sha before `2cbf0ec0…5629a`, after `d9b3483f…38119271`
  - verified: `node --check` OK, service restarted healthy, `Can't bind
    mount` gone from run-logs.
- Rollback: copy backup over the file + `paperclipai service restart --wait`.
- Re-apply after `paperclip update` (overwrites node_modules):
  1. `ls /home/paperclip/.paperclip/cli/installs/npm/` (new version dir)
  2. backup new file + sha256sum
  3. re-apply the diff below, `node --check`, record SHAs
  4. restart service, check `/api/health`, `ss -tlnp | grep 3100`
  5. single trivial trial before real work
- Diff:

```diff
@@ after unconditional --symlink push
+        // Local carry of upstream paperclip#14178 (merged-/usr compat).
+        // Bind-mounting the host symlink before /usr is mounted leaves a
+        // dangling destination; recreate the host link and skip the bind.
+        // Real directories still bind. Zero confinement change.
+        const usrSymlinkAliases = new Set();
+        for (const alias of ["/bin", "/sbin", "/lib", "/lib64"]) {
+            try {
+                const aliasStat = await fs.lstat(alias);
+                if (!aliasStat.isSymbolicLink())
+                    continue;
+                const linkTarget = await fs.readlink(alias);
+                const resolvedTarget = path.resolve(path.dirname(alias), linkTarget);
+                if (resolvedTarget === "/usr" || resolvedTarget.startsWith("/usr/")) {
+                    args.push("--symlink", linkTarget, alias);
+                    usrSymlinkAliases.add(alias);
+                }
+            }
+            catch {
+            }
+        }
@@ in mount() + SYSTEM_READ_PATHS loop
+        skip any path in usrSymlinkAliases (both places)
```

- Follow-up live blocker (separate): Codex 0.160.0 trusted-directory check
  fails on fallback workspaces (`--skip-git-repo-check` missing on that
  path) — under investigation, NOT fixed by this patch.
