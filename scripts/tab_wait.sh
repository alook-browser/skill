#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="tab_wait.sh"
USAGE="usage: tab_wait.sh <tabId> [--timeout MS] [--token TOKEN]"
DESCRIPTION="Wait for a tab load state."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="${ALOOK_ACCESS_TOKEN:-${SKILL_ACCESS_TOKEN:-}}"
timeout=""

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
shift_count=0
tab_id="${1:-}"
[[ -n "$tab_id" ]] || skill_wrapper_die "$WRAPPER" "missing required argument: <tabId>"
shift_count=1
(( shift_count > 0 )) && shift "$shift_count" || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      token="$2"
      shift 2
      ;;
    --timeout)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      timeout="$2"
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

[[ -z "$timeout" || "$timeout" =~ ^-?[0-9]+$ ]] || skill_wrapper_die "$WRAPPER" "--timeout must be an integer"
[[ -n "$token" ]] || skill_wrapper_die "$WRAPPER" "missing access token; pass --token or set ALOOK_ACCESS_TOKEN"
if [[ -n "$timeout" ]] && (( timeout < 100 || timeout > 120000 )); then skill_wrapper_die "$WRAPPER" "--timeout must be between 100 and 120000 milliseconds"; fi

args=(command tab_wait --token "$token")
args+=(--string tabId "$tab_id")
[[ -n "$timeout" ]] && args+=(--int timeout "$timeout")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
