# 🆘 github-intelligence-emergency

## Providing account-wide intelligence repo emergency control

Searches for `.github-*-intelligence` folders across all repositories and provides last-line-of-defence workflow modification and deletion for total agent control.

## Instructions

0. Create a repository secret named `INTELLIGENCE_EMERGENCY_TOKEN` containing a Personal Access Token (PAT) with `repo` scope across the organisation. This is required for cross-repository operations.

1. Delete `DELETE-TO-ACTIVATE.md` to remove the final fail-safe. While present, all operations run in dry-run mode only.

2. Delete the appropriate trigger file to activate the emergency measure.
