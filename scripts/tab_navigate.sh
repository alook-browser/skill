#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="tab_navigate.sh"
USAGE="usage: tab_navigate.sh <url> [--tab-id ID] [--token TOKEN]"
DESCRIPTION="Navigate an existing tab."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="${ALOOK_ACCESS_TOKEN:-${SKILL_ACCESS_TOKEN:-}}"
tab_id=""

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
shift_count=0
url="${1:-}"
[[ -n "$url" ]] || skill_wrapper_die "$WRAPPER" "missing required argument: <url>"
shift_count=1
(( shift_count > 0 )) && shift "$shift_count" || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      token="$2"
      shift 2
      ;;
    --tab-id)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      tab_id="$2"
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

[[ -n "$token" ]] || skill_wrapper_die "$WRAPPER" "missing access token; pass --token or set ALOOK_ACCESS_TOKEN"

args=(command tab_navigate --token "$token")
args+=(--string url "$url")
[[ -n "$tab_id" ]] && args+=(--string tabId "$tab_id")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
