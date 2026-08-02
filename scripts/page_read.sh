#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="page_read.sh"
USAGE="usage: page_read.sh <tabId> [--cursor CURSOR] [--mode article|dynamic] [--token TOKEN]"
DESCRIPTION="Read article, page, or dynamic content blocks."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="${ALOOK_ACCESS_TOKEN:-${SKILL_ACCESS_TOKEN:-}}"
cursor=""
mode=""

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
    --cursor)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      cursor="$2"
      shift 2
      ;;
    --mode)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      mode="$2"
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

args=(command page_read --token "$token")
args+=(--string tabId "$tab_id")
[[ -n "$cursor" ]] && args+=(--string cursor "$cursor")
[[ -n "$mode" ]] && args+=(--string mode "$mode")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
