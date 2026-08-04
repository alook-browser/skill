#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="tab_execute_js.sh"
USAGE="usage: tab_execute_js.sh <tabId> <script> [--await-promise] [--timeout MS] [--token TOKEN]"
DESCRIPTION="Run JavaScript inside a tab and return the result."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="$(skill_wrapper_default_access_token)"
await_promise="false"
timeout=""

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
shift_count=0
tab_id="${1:-}"
[[ -n "$tab_id" ]] || skill_wrapper_die "$WRAPPER" "missing required argument: <tabId>"
shift_count=1
script="${2:-}"
[[ -n "$script" ]] || skill_wrapper_die "$WRAPPER" "missing required argument: <script>"
shift_count=2
(( shift_count > 0 )) && shift "$shift_count" || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      token="$2"
      shift 2
      ;;
    --await-promise)
      await_promise="true"
      shift
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
[[ -n "$token" ]] || skill_wrapper_die "$WRAPPER" "missing access token; pass --token or run access.sh, then access_confirm.sh"

args=(command tab_execute_js --token "$token")
args+=(--string tabId "$tab_id")
args+=(--string script "$script")
[[ -n "$await_promise" ]] && args+=(--bool awaitPromise "$await_promise")
[[ -n "$timeout" ]] && args+=(--int timeout "$timeout")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
