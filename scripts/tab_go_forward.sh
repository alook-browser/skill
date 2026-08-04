#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="tab_go_forward.sh"
USAGE="usage: tab_go_forward.sh [tabId] [--token TOKEN]"
DESCRIPTION="Go forward in one tab history."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="$(skill_wrapper_default_access_token)"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
shift_count=0
tab_id=""
if [[ $# -ge 1 && "${1:-}" != --* ]]; then
  tab_id="${1}"
  shift_count=1
fi
(( shift_count > 0 )) && shift "$shift_count" || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      token="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      skill_wrapper_die "$WRAPPER" "unknown option: $1"
      ;;
  esac
done

[[ -n "$token" ]] || skill_wrapper_die "$WRAPPER" "missing access token; pass --token or run access.sh, then access_confirm.sh"

args=(command tab_go_forward --token "$token")
[[ -n "$tab_id" ]] && args+=(--string tabId "$tab_id")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
