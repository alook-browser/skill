#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="query_all.sh"
USAGE="usage:
  query_all.sh <tabId> <query> [--limit N] [--fields CSV] [--text-limit N] [--token TOKEN]
  query_all.sh <tabId> --css CSS [--limit N] [--fields CSV] [--text-limit N] [--token TOKEN]
  query_all.sh <tabId> --role ROLE [--name NAME] [--limit N] [--fields CSV] [--text-limit N] [--token TOKEN]"
DESCRIPTION="List all matched visible targets."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="${ALOOK_ACCESS_TOKEN:-${SKILL_ACCESS_TOKEN:-}}"
css=""
role=""
name=""
point_json=""
limit=""
fields_csv=""
text_limit=""

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
shift_count=0
tab_id="${1:-}"
[[ -n "$tab_id" ]] || skill_wrapper_die "$WRAPPER" "missing required argument: <tabId>"
shift_count=1
query=""
if [[ $# -ge 2 && "${2:-}" != --* ]]; then
  query="${2}"
  shift_count=2
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
    --limit)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      limit="$2"
      shift 2
      ;;
    --fields)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      fields_csv="$2"
      shift 2
      ;;
    --text-limit)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      text_limit="$2"
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

[[ -z "$limit" || "$limit" =~ ^-?[0-9]+$ ]] || skill_wrapper_die "$WRAPPER" "--limit must be an integer"
[[ -z "$text_limit" || "$text_limit" =~ ^-?[0-9]+$ ]] || skill_wrapper_die "$WRAPPER" "--text-limit must be an integer"
[[ -n "$token" ]] || skill_wrapper_die "$WRAPPER" "missing access token; pass --token or set ALOOK_ACCESS_TOKEN"
[[ -z "$name" || -n "$role" ]] || skill_wrapper_die "$WRAPPER" "--name requires --role"
target_family_count=0
[[ -n "${query:-}" ]] && ((target_family_count += 1))
[[ -n "$css" ]] && ((target_family_count += 1))
if [[ -n "$role" || -n "$name" ]]; then
  ((target_family_count += 1))
fi
[[ -z "$point_json" ]] || skill_wrapper_die "$WRAPPER" "--point-json is not supported by this action"
[[ "$target_family_count" -ge 1 ]] || skill_wrapper_die "$WRAPPER" "one of <query> --css --role [--name] is required"
[[ "$target_family_count" -le 1 ]] || skill_wrapper_die "$WRAPPER" "only one target family is allowed"

args=(command query_all --token "$token")
[[ -n "${query:-}" ]] && args+=(--string query "$query")
[[ -n "$css" ]] && args+=(--string css "$css")
if [[ -n "$role" || -n "$name" ]]; then
  [[ -n "$role" ]] && args+=(--string role "$role")
  [[ -n "$name" ]] && args+=(--string name "$name")
fi
args+=(--string tabId "$tab_id")
[[ -n "$limit" ]] && args+=(--int limit "$limit")
[[ -n "$fields_csv" ]] && args+=(--json fields "$(skill_wrapper_json_string_array_from_csv "$fields_csv")")
[[ -n "$text_limit" ]] && args+=(--int textLimit "$text_limit")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
