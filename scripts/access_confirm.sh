#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="access_confirm.sh"
USAGE="usage: access_confirm.sh <challengeId>"
DESCRIPTION="Confirm an access challenge and return an access token."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
shift_count=0
challenge_id="${1:-}"
[[ -n "$challenge_id" ]] || skill_wrapper_die "$WRAPPER" "missing required argument: <challengeId>"
shift_count=1
(( shift_count > 0 )) && shift "$shift_count" || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    *)
      skill_wrapper_die "$WRAPPER" "unknown option: $1"
      ;;
  esac
done

exec "$SKILL_WRAPPER_CORE" access-confirm --challenge-id "$challenge_id"
