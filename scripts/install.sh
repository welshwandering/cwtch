#!/bin/bash
#
# Install claude utilities by symlinking to ~/.local/bin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly BIN_DIR="${HOME}/.local/bin"

log() { echo "[install] $*"; }

main() {
  mkdir -p "${BIN_DIR}"

  for script in "${SCRIPT_DIR}"/*.sh; do
    [[ "$(basename "${script}")" == "install.sh" ]] && continue
    local name="${script%.sh}"; name="${name##*/}"
    local target="${BIN_DIR}/${name}"
    ln -sf "${script}" "${target}"
    log "Linked ${name} -> ${target}"
  done

  if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]]; then
    local rc_file
    case "${SHELL}" in
      */zsh)  rc_file="${HOME}/.zshrc" ;;
      */bash) rc_file="${HOME}/.bashrc" ;;
      *)      rc_file="your shell rc file" ;;
    esac
    echo ""
    echo "WARNING: ${BIN_DIR} is not in PATH"
    echo "Add to ${rc_file}:"
    echo "  export PATH=\"\${HOME}/.local/bin:\${PATH}\""
  else
    log "PATH already includes ${BIN_DIR}"
  fi
}

main "$@"
