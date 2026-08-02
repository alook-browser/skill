#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="drag.sh"
USAGE="usage: drag.sh <tabId> --from-json JSON --to-json JSON [--steps N] [--duration-ms N] [--button left] [--token TOKEN]"
DESCRIPTION="Drag from one point or target to another."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="${ALOOK_ACCESS_TOKEN:-${SKILL_ACCESS_TOKEN:-}}"
from_json=""
to_json=""
steps=""
duration_ms=""
button=""

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
    --from-json)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      from_json="$2"
      shift 2
      ;;
    --to-json)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      to_json="$2"
      shift 2
      ;;
    --steps)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      steps="$2"
      shift 2
      ;;
    --duration-ms)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      duration_ms="$2"
      shift 2
      ;;
    --button)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      button="$2"
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

[[ -z "$steps" || "$steps" =~ ^-?[0-9]+$ ]] || skill_wrapper_die "$WRAPPER" "--steps must be an integer"
[[ -z "$duration_ms" || "$duration_ms" =~ ^-?[0-9]+$ ]] || skill_wrapper_die "$WRAPPER" "--duration-ms must be an integer"
[[ -n "$token" ]] || skill_wrapper_die "$WRAPPER" "missing access token; pass --token or set ALOOK_ACCESS_TOKEN"

args=(command drag --token "$token")
args+=(--string tabId "$tab_id")
[[ -n "$from_json" ]] || skill_wrapper_die "$WRAPPER" "from is required"
args+=(--json from "$from_json")
[[ -n "$to_json" ]] || skill_wrapper_die "$WRAPPER" "to is required"
args+=(--json to "$to_json")
[[ -n "$steps" ]] && args+=(--int steps "$steps")
[[ -n "$duration_ms" ]] && args+=(--int durationMs "$duration_ms")
[[ -n "$button" ]] && args+=(--string button "$button")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
