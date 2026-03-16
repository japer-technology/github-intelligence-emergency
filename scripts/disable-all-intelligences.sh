#!/usr/bin/env bash
# disable-all-intelligences.sh
# Finds all repos in the account/org with .github-*-intelligence folders
# and moves their .github/workflows/*.yml files to .github/workflows-DISABLED/
#
# Usage: DRY_RUN=true|false GITHUB_TOKEN=<token> ./scripts/disable-all-intelligences.sh
#
# Environment variables:
#   GITHUB_TOKEN  – a token with repo scope for the target owner
#   OWNER         – the GitHub user or organisation (default: extracted from GITHUB_REPOSITORY)
#   DRY_RUN       – when "true", no changes are made; a receipt is written instead

set -euo pipefail

: "${GITHUB_TOKEN:?GITHUB_TOKEN is required}"
: "${OWNER:=${GITHUB_REPOSITORY%%/*}}"
: "${DRY_RUN:=true}"

API="https://api.github.com"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
ACCEPT_HEADER="Accept: application/vnd.github+json"
LOG_DIR="${GITHUB_WORKSPACE:-$(pwd)}/dry-run-log"

log() { echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"; }

# ── Collect all repos visible to the token for the owner (sorted by name) ──
fetch_repos() {
  local page=1
  local per_page=100
  local all_repos=""
  while :; do
    local response
    response=$(curl -sf -H "${AUTH_HEADER}" -H "${ACCEPT_HEADER}" \
      "${API}/orgs/${OWNER}/repos?per_page=${per_page}&page=${page}&type=all" 2>/dev/null) \
    || response=$(curl -sf -H "${AUTH_HEADER}" -H "${ACCEPT_HEADER}" \
      "${API}/users/${OWNER}/repos?per_page=${per_page}&page=${page}&type=all" 2>/dev/null) \
    || { log "ERROR: failed to list repos for ${OWNER}"; return 1; }

    local names
    names=$(echo "${response}" | jq -r '.[].name // empty')
    [ -z "${names}" ] && break
    all_repos+="${names}"$'\n'
    page=$((page + 1))
  done
  echo "${all_repos}" | sed '/^$/d' | sort
}

# ── Check whether a repo contains .github-*-intelligence dirs and return them ──
get_intelligence_folders() {
  local repo=$1
  local contents
  contents=$(curl -sf -H "${AUTH_HEADER}" -H "${ACCEPT_HEADER}" \
    "${API}/repos/${OWNER}/${repo}/contents/" 2>/dev/null) || return 1
  echo "${contents}" | jq -r '.[] | select(.type=="dir" and (.name | test("^\\.github-.*-intelligence$"))) | .name'
}

# ── Extract version from a workflow file ─────────────────────────────
extract_workflow_version() {
  local repo=$1 file=$2
  local file_path=".github/workflows/${file}"
  local file_meta
  file_meta=$(curl -sf -H "${AUTH_HEADER}" -H "${ACCEPT_HEADER}" \
    "${API}/repos/${OWNER}/${repo}/contents/${file_path}" 2>/dev/null) || { echo "unknown"; return; }

  local content
  content=$(echo "${file_meta}" | jq -r '.content // empty' | base64 -d 2>/dev/null) || { echo "unknown"; return; }

  # Look for version pattern in comments: "# version: X.Y.Z"
  local version
  version=$(echo "${content}" | grep -i -m1 '^#\s*version\s*[:=]' | sed 's/^#\s*[Vv]ersion\s*[:=]\s*//; s/\s*$//')
  [ -z "${version}" ] && version="unknown"
  echo "${version}"
}

# ── Disable workflows for a single repo ──────────────────────────────
disable_repo_workflows() {
  local repo=$1
  log "Processing repo: ${OWNER}/${repo}"

  # List workflow files
  local workflows
  workflows=$(curl -sf -H "${AUTH_HEADER}" -H "${ACCEPT_HEADER}" \
    "${API}/repos/${OWNER}/${repo}/contents/.github/workflows" 2>/dev/null) || {
    log "  No .github/workflows directory found – skipping"
    return 0
  }

  local files
  files=$(echo "${workflows}" | jq -r '.[] | select(.type=="file" and (.name | test("\\.(yml|yaml)$"))) | .name')
  [ -z "${files}" ] && { log "  No workflow files found – skipping"; return 0; }

  while IFS= read -r file; do
    [ -z "${file}" ] && continue
    local src_path=".github/workflows/${file}"
    local dst_path=".github/workflows-DISABLED/${file}"

    local version
    version=$(extract_workflow_version "${repo}" "${file}")
    log "  Workflow: ${file} (version: ${version})"

    if [ "${DRY_RUN}" = "true" ]; then
      log "  [DRY RUN] Would move ${src_path} → ${dst_path}"
      continue
    fi

    log "  Moving ${src_path} → ${dst_path}"

    # Get the file content and SHA
    local file_meta
    file_meta=$(curl -sf -H "${AUTH_HEADER}" -H "${ACCEPT_HEADER}" \
      "${API}/repos/${OWNER}/${repo}/contents/${src_path}" 2>/dev/null) || {
      log "  WARNING: could not read ${src_path}"; continue
    }

    local content sha
    content=$(echo "${file_meta}" | jq -r '.content')
    sha=$(echo "${file_meta}" | jq -r '.sha')

    # Create the file at the new location
    curl -sf -X PUT -H "${AUTH_HEADER}" -H "${ACCEPT_HEADER}" \
      -d "$(jq -n --arg msg "🆘 Emergency disable: move ${file} to workflows-DISABLED" \
                   --arg content "${content}" \
                   '{message: $msg, content: $content}')" \
      "${API}/repos/${OWNER}/${repo}/contents/${dst_path}" >/dev/null || {
      log "  WARNING: could not create ${dst_path}"; continue
    }

    # Delete the original file
    curl -sf -X DELETE -H "${AUTH_HEADER}" -H "${ACCEPT_HEADER}" \
      -d "$(jq -n --arg msg "🆘 Emergency disable: remove original ${file}" \
                   --arg sha "${sha}" \
                   '{message: $msg, sha: $sha}')" \
      "${API}/repos/${OWNER}/${repo}/contents/${src_path}" >/dev/null || {
      log "  WARNING: could not delete original ${src_path}"; continue
    }

    log "  ✓ ${file} disabled"
  done <<< "${files}"
}

# ── Main ─────────────────────────────────────────────────────────────
main() {
  log "=== Disable All Intelligences ==="
  log "Owner: ${OWNER}"
  log "Dry run: ${DRY_RUN}"
  echo ""

  local repos
  repos=$(fetch_repos) || exit 1

  local receipt=""
  local found=0

  while IFS= read -r repo; do
    [ -z "${repo}" ] && continue

    local intel_folders
    intel_folders=$(get_intelligence_folders "${repo}") || continue
    [ -z "${intel_folders}" ] && continue

    found=$((found + 1))
    receipt+="REPO: ${OWNER}/${repo}"$'\n'

    # Include intelligence folders in receipt
    while IFS= read -r f; do
      [ -n "${f}" ] && receipt+="  FOLDER: ${f}"$'\n'
    done <<< "${intel_folders}"

    # Include workflow versions in receipt
    local workflows
    workflows=$(curl -sf -H "${AUTH_HEADER}" -H "${ACCEPT_HEADER}" \
      "${API}/repos/${OWNER}/${repo}/contents/.github/workflows" 2>/dev/null) || true
    if [ -n "${workflows}" ]; then
      local wf_files
      wf_files=$(echo "${workflows}" | jq -r '.[] | select(.type=="file" and (.name | test("\\.(yml|yaml)$"))) | .name' 2>/dev/null)
      while IFS= read -r wf; do
        [ -z "${wf}" ] && continue
        local ver
        ver=$(extract_workflow_version "${repo}" "${wf}")
        receipt+="  WORKFLOW: ${wf} (version: ${ver})"$'\n'
      done <<< "${wf_files}"
    fi

    disable_repo_workflows "${repo}"
  done <<< "${repos}"

  log ""
  log "Repos with intelligence folders found: ${found}"

  # Write dry-run receipt
  if [ "${DRY_RUN}" = "true" ]; then
    mkdir -p "${LOG_DIR}"
    local receipt_file="${LOG_DIR}/disable-all-intelligences-$(date -u '+%Y%m%dT%H%M%SZ').log"
    {
      echo "=== Disable All Intelligences – Dry Run Receipt ==="
      echo "Timestamp: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
      echo "Owner: ${OWNER}"
      echo "Intelligence repos found: ${found}"
      echo ""
      echo "${receipt}"
    } > "${receipt_file}"
    log "Dry-run receipt written to ${receipt_file}"
  fi

  log "=== Done ==="
}

main "$@"
