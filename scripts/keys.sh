#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="keys.sh"
USAGE="usage:
  keys.sh <tabId> <key> [--modifiers CSV] [--token TOKEN]
  keys.sh <tabId> <key> <query> [--modifiers CSV] [--token TOKEN]
  keys.sh <tabId> <key> --css CSS [--modifiers CSV] [--token TOKEN]
  keys.sh <tabId> <key> --role ROLE [--name NAME] [--modifiers CSV] [--token TOKEN]"
DESCRIPTION="Send one keyboard key sequence to the page or one target."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="$(skill_wrapper_default_access_token)"
css=""
role=""
name=""
point_json=""
modifiers_csv=""

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
shift_count=0
tab_id="${1:-}"
[[ -n "$tab_id" ]] || skill_wrapper_die "$WRAPPER" "missing required argument: <tabId>"
shift_count=1
key="${2:-}"
[[ -n "$key" ]] || skill_wrapper_die "$WRAPPER" "missing required argument: <key>"
shift_count=2
query=""
if [[ $# -ge 3 && "${3:-}" != --* ]]; then
  query="${3}"
  shift_count=3
fi
(( shift_count > 0 )) && shift "$shift_count" || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      token="$2"
      shift 2
      ;;
    --css)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      css="$2"
      shift 2
      ;;
    --role)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      role="$2"
      shift 2
      ;;
    --name)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      name="$2"
      shift 2
      ;;
    --modifiers)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      modifiers_csv="$2"
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
[[ -z "$name" || -n "$role" ]] || skill_wrapper_die "$WRAPPER" "--name requires --role"
target_family_count=0
[[ -n "${query:-}" ]] && ((target_family_count += 1))
[[ -n "$css" ]] && ((target_family_count += 1))
if [[ -n "$role" || -n "$name" ]]; then
  ((target_family_count += 1))
fi
[[ -z "$point_json" ]] || skill_wrapper_die "$WRAPPER" "--point-json is not supported by this action"
[[ "$target_family_count" -le 1 ]] || skill_wrapper_die "$WRAPPER" "only one target family is allowed"

args=(command press_key --token "$token")
[[ -n "${query:-}" ]] && args+=(--string query "$query")
[[ -n "$css" ]] && args+=(--string css "$css")
if [[ -n "$role" || -n "$name" ]]; then
  [[ -n "$role" ]] && args+=(--string role "$role")
  [[ -n "$name" ]] && args+=(--string name "$name")
fi
args+=(--string tabId "$tab_id")
args+=(--string key "$key")
[[ -n "$modifiers_csv" ]] && args+=(--json modifiers "$(skill_wrapper_json_string_array_from_csv "$modifiers_csv")")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
