#!/bin/bash
#
# Switch between Claude Code accounts.

set -euo pipefail

readonly CLAUDE_DIR="${HOME}/.claude"
readonly ACCOUNTS_DIR="${HOME}/.claude-accounts"
readonly CURRENT_FILE="${ACCOUNTS_DIR}/.current"

err() { echo "[ERROR] $*" >&2; }
log() { echo "[claude-switch] $*"; }

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [args]

Commands:
  list            List all saved accounts
  current         Show current active account
  use <name>      Switch to account <name>
  save <name>     Save current session as <name>
  delete <name>   Delete saved account <name>

Examples:
  $(basename "$0") save work
  $(basename "$0") use personal
EOF
}

list_accounts() {
  mkdir -p "${ACCOUNTS_DIR}"
  local current=""
  [[ -f "${CURRENT_FILE}" ]] && current="$(cat "${CURRENT_FILE}")"
  local found=0
  for dir in "${ACCOUNTS_DIR}"/*/; do
    [[ -d "${dir}" ]] || continue
    found=1
    local name="${dir%/}"; name="${name##*/}"
    [[ "${name}" == "${current}" ]] && echo "* ${name} (active)" || echo "  ${name}"
  done
  [[ ${found} -eq 0 ]] && echo "No accounts saved. Use 'save <name>' to save current session."
  return 0
}

save_account() {
  local name="$1" target="${ACCOUNTS_DIR}/${1}"
  mkdir -p "${ACCOUNTS_DIR}"
  [[ -d "${CLAUDE_DIR}" ]] || { err "No Claude session at ${CLAUDE_DIR}"; exit 1; }
  rm -rf "${target}"
  cp -r "${CLAUDE_DIR}" "${target}"
  echo "${name}" > "${CURRENT_FILE}"
  log "Saved current session as '${name}'"
}

use_account() {
  local name="$1" source="${ACCOUNTS_DIR}/${1}"
  [[ -d "${source}" ]] || { err "Account '${name}' not found"; exit 1; }
  rm -rf "${CLAUDE_DIR}"
  cp -r "${source}" "${CLAUDE_DIR}"
  echo "${name}" > "${CURRENT_FILE}"
  log "Switched to '${name}'"
}

delete_account() {
  local name="$1" target="${ACCOUNTS_DIR}/${1}"
  [[ -d "${target}" ]] || { err "Account '${name}' not found"; exit 1; }
  rm -rf "${target}"
  if [[ -f "${CURRENT_FILE}" ]]; then
    local cur
    cur="$(cat "${CURRENT_FILE}")"
    [[ "${cur}" == "${name}" ]] && rm -f "${CURRENT_FILE}"
  fi
  log "Deleted '${name}'"
}

main() {
  [[ $# -lt 1 ]] && { usage; exit 1; }
  local cmd="$1"; shift
  case "${cmd}" in
    list) list_accounts ;;
    current) [[ -f "${CURRENT_FILE}" ]] && cat "${CURRENT_FILE}" || echo "(none)" ;;
    save)   [[ $# -lt 1 ]] && { err "Missing name"; exit 1; }; save_account "$1" ;;
    use)    [[ $# -lt 1 ]] && { err "Missing name"; exit 1; }; use_account "$1" ;;
    delete) [[ $# -lt 1 ]] && { err "Missing name"; exit 1; }; delete_account "$1" ;;
    -h|--help) usage ;;
    *) err "Unknown: ${cmd}"; usage; exit 1 ;;
  esac
}

main "$@"
