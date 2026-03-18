# 🆘 github-intelligence-emergency

## Organisation-wide emergency control for intelligence repositories

#### Finds `.github-*-intelligence` folders across all repositories and enables last-resort workflow updates or removal to retain full control of deployed agents.

<p align="center">
  <picture>
    <img src="https://raw.githubusercontent.com/japer-technology/github-intelligence-emergency/main/THE-LAST-LINE.png" alt="GitHub Intelligence Emergency" width="500">
  </picture>
</p>

> A 007 elite agent entrusted with absolute authority over all AI agents, for true control belongs to the one who can destroy a thing.

## 🔴 Instructions

0. Create a repository secret named `INTELLIGENCE_EMERGENCY_TOKEN` containing a Personal Access Token (PAT) with `repo` scope across the organisation. This is required for cross-repository operations.

1. Delete `DELETE-TO-ACTIVATE.md` to remove the final fail-safe. While present, all operations run in dry-run mode only.

2. Delete the appropriate trigger file to activate the emergency measure.

---

## 🔴 Protocols

### 🔒 Disable All Intelligences

**Trigger:** Delete `DELETE-TO-DISABLE-ALL-INTELLIGENCES.md`

The Disable protocol is a **reversible** operation designed to halt all intelligence workflows across the organisation without destroying them.

#### What happens

1. The workflow detects that `DELETE-TO-DISABLE-ALL-INTELLIGENCES.md` has been deleted (verified via `git diff --diff-filter=D` to ensure the file was actually deleted, not just modified).
2. It checks whether the fail-safe file `DELETE-TO-ACTIVATE.md` still exists:
   - **If present** → the operation runs in **dry-run mode** and writes a timestamped receipt to `dry-run-log/`.
   - **If absent** → the operation runs **live**.
3. The script enumerates every repository visible to the token for the organisation/user.
4. For each repository that contains one or more `.github-*-intelligence` folders, all `.github/workflows/*.yml` workflow files are **moved** to `.github/workflows-DISABLED/`.

#### Result

Intelligence workflows are relocated out of the active workflows directory. GitHub Actions will no longer execute them, but the files remain intact and can be moved back to restore functionality.

---

### ☠️ Kill All Intelligences

**Trigger:** Delete `DELETE-TO-KILL-ALL-INTELLIGENCES.md`

The Kill protocol is a **destructive, irreversible** operation that permanently removes all intelligence workflows and their associated configuration folders across the organisation.

#### What happens

1. The workflow detects that `DELETE-TO-KILL-ALL-INTELLIGENCES.md` has been deleted (verified via `git diff --diff-filter=D` to ensure the file was actually deleted, not just modified).
2. It checks whether the fail-safe file `DELETE-TO-ACTIVATE.md` still exists:
   - **If present** → the operation runs in **dry-run mode** and writes a timestamped receipt to `dry-run-log/`.
   - **If absent** → the operation runs **live**.
3. The script enumerates every repository visible to the token for the organisation/user.
4. For each repository that contains one or more `.github-*-intelligence` folders:
   1. All `.github/workflows/*.yml` workflow files are **deleted**.
   2. Every `.github-*-intelligence` folder and its contents are **recursively deleted**.

#### Result

All intelligence workflows and intelligence folders are permanently removed from every affected repository. This action cannot be undone.

---

### 🛡️ Fail-safe: `DELETE-TO-ACTIVATE.md`

While `DELETE-TO-ACTIVATE.md` exists in the repository, **both protocols are forced into dry-run mode**. No live changes will be made to any repository regardless of which trigger file is deleted.

- Scripts default `DRY_RUN` to `true` if the environment variable is unset.
- Workflows check for the presence of the fail-safe file and set `DRY_RUN` accordingly.
- Dry-run receipts are committed to `dry-run-log/` so you can review exactly what would have happened.

Delete `DELETE-TO-ACTIVATE.md` **first** to enable live execution.

---

### 🔍 Manual Dry-Run

You can simulate either protocol at any time without deleting any trigger files by running the **🔍 Dry-Run** workflow manually via `workflow_dispatch`.

1. Navigate to **Actions → 🔍 Dry-Run → Run workflow**.
2. Select the operation to simulate (`disable-all-intelligences` or `kill-all-intelligences`).
3. A receipt is committed to `dry-run-log/` describing what would have happened.
