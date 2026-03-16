# 🔍 Dry-Run Logs

This directory contains timestamped receipts produced by dry-run executions of the emergency workflows.

## How logs are generated

1. **Manual dry-run** — Run the **🔍 Dry-Run** workflow (`workflow_dispatch`). Choose an operation (`disable-all-intelligences` or `kill-all-intelligences`) and a receipt is committed here automatically.

2. **Fail-safe dry-run** — Delete a `DELETE-TO-*.md` trigger file while `DELETE-TO-ACTIVATE.md` still exists. Because the fail-safe is active, the workflow runs in dry-run mode and writes a receipt here instead of making live changes.

## Log file naming

```
<operation>-<UTC timestamp>.log
```

For example: `disable-all-intelligences-20260316T041646Z.log`

## What a receipt contains

- Operation name and timestamp
- Organisation/owner scanned
- Number of repositories that contain `.github-*-intelligence` folders
- Per-repository listing of matched repos
