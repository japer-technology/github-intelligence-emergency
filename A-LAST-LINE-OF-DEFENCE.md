# 🛡️ A Last Line of Defence

## How the emergency system prevents accidental execution

This repository implements a **multi-layered safety architecture** to ensure that no intelligence workflows or folders are modified or destroyed by accident. Every layer must be deliberately bypassed before any live operation takes place.

<p align="center">
  <picture>
    <img src="https://raw.githubusercontent.com/japer-technology/github-intelligence-emergency/main/THE-LAST-LINE.png" alt="GitHub Intelligence Emergency" width="500">
  </picture>
</p>

### Layer 1 — Fail-safe file: `DELETE-TO-ACTIVATE.md`

While `DELETE-TO-ACTIVATE.md` exists in the repository, **all operations are forced into dry-run mode**. Both the trigger workflows and the underlying shell scripts enforce this:

- The workflows check for the file's presence and set `DRY_RUN=true` when it is found.
- The scripts default `DRY_RUN` to `true` if the environment variable is unset.
- Dry-run receipts are committed to `dry-run-log/` so you can audit exactly what would have happened.

**You must delete `DELETE-TO-ACTIVATE.md` first** to enable live execution of any protocol.

---

### Layer 2 — Trigger files: `DELETE-TO-*.md`

Each emergency protocol is gated behind its own trigger file:

| Trigger file | Protocol |
|---|---|
| `DELETE-TO-DISABLE-ALL-INTELLIGENCES.md` | 🔒 Disable — moves workflows to `workflows-DISABLED/` (reversible) |
| `DELETE-TO-KILL-ALL-INTELLIGENCES.md` | ☠️ Kill — deletes workflows and intelligence folders (irreversible) |

The corresponding workflow only fires when a push is detected on that file's path. The workflow then verifies with `git diff --diff-filter=D` that the file was **actually deleted** — renaming, editing, or merely touching the file will not activate the protocol.

---

### Layer 3 — Token scope: `INTELLIGENCE_EMERGENCY_TOKEN`

A Personal Access Token (PAT) with `repo` scope across the organisation must be stored as a repository secret named `INTELLIGENCE_EMERGENCY_TOKEN`. Without this token:

- The scripts cannot enumerate repositories.
- The scripts cannot read, move, or delete files in other repositories.
- The emergency workflows will fail harmlessly.

---

### Layer 4 — Manual workflow placement

The agent workflow (`github-intelligence-emergency-agent.yml`) installs companion workflows into `.github/workflows-new/` — **not** the active `.github/workflows/` directory. The user must **manually** move the trigger and dry-run workflows into `.github/workflows/` to activate them. This prevents the trigger workflows from becoming active without deliberate human action.

---

### Layer 5 — Dry-run workflow

The `🔍 Dry-Run` workflow (`workflow_dispatch` only) allows you to simulate either protocol at any time without deleting any files. It always forces `DRY_RUN=true` regardless of whether the fail-safe file exists. Use it to preview exactly what would happen before committing to a live execution.

---

## Summary of activation sequence

To execute a live emergency protocol, **all** of the following must be true:

1. `INTELLIGENCE_EMERGENCY_TOKEN` secret is configured with a valid PAT.
2. The trigger workflows have been moved from `.github/workflows-new/` to `.github/workflows/`.
3. `DELETE-TO-ACTIVATE.md` has been deleted (fail-safe removed).
4. The appropriate `DELETE-TO-*.md` trigger file has been deleted (not renamed or edited).

Only when every layer has been deliberately bypassed will the system execute live changes across the organisation's repositories.
