#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="dialog_handle.sh"
USAGE="usage: dialog_handle.sh <tabId> <accept|dismiss> [--text TEXT | --text-file FILE | --text-stdin] [--token TOKEN]"
DESCRIPTION="Accept or dismiss the current JavaScript dialog."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="$(skill_wrapper_default_access_token)"
text_value=""
text_source=""

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
shift_count=0
tab_id="${1:-}"
[[ -n "$tab_id" ]] || skill_wrapper_die "$WRAPPER" "missing required argument: <tabId>"
shift_count=1
decision="${2:-}"
[[ -n "$decision" ]] || skill_wrapper_die "$WRAPPER" "missing required argument: <decision>"
shift_count=2
(( shift_count > 0 )) && shift "$shift_count" || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      token="$2"
      shift 2
      ;;
    --text)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      [[ -z "$text_source" ]] || skill_wrapper_die "$WRAPPER" "only one text input source is allowed"
      text_value="$2"
      text_source="arg"
      shift 2
      ;;
    --text-file)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      [[ -z "$text_source" ]] || skill_wrapper_die "$WRAPPER" "only one text input source is allowed"
      [[ -f "$2" ]] || skill_wrapper_die "$WRAPPER" "file not found: $2"
      text_value="$(cat "$2")"
      text_source="file"
      shift 2
      ;;
    --text-stdin)
      [[ -z "$text_source" ]] || skill_wrapper_die "$WRAPPER" "only one text input source is allowed"
      [[ -t 0 ]] && skill_wrapper_die "$WRAPPER" "--text-stdin requires piped stdin"
      text_value="$(cat)"
      text_source="stdin"
      shift
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

args=(command dialog_handle --token "$token")
args+=(--string tabId "$tab_id")
args+=(--string decision "$decision")
[[ -n "$text_value" ]] && args+=(--string text "$text_value")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
