#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="click.sh"
USAGE="usage:
  click.sh <tabId> <query> [--button left|right] [--click-count 1|2] [--token TOKEN]
  click.sh <tabId> --css CSS [--button left|right] [--click-count 1|2] [--token TOKEN]
  click.sh <tabId> --role ROLE [--name NAME] [--button left|right] [--click-count 1|2] [--token TOKEN]
  click.sh <tabId> --point-json JSON [--button left|right] [--click-count 1|2] [--token TOKEN]"
DESCRIPTION="Click one visible interactive target."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="${ALOOK_ACCESS_TOKEN:-${SKILL_ACCESS_TOKEN:-}}"
css=""
role=""
name=""
point_json=""
button=""
click_count=""

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
    --point-json)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      point_json="$2"
      shift 2
      ;;
    --button)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      button="$2"
      shift 2
      ;;
    --click-count)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      click_count="$2"
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

[[ -z "$click_count" || "$click_count" =~ ^-?[0-9]+$ ]] || skill_wrapper_die "$WRAPPER" "--click-count must be an integer"
[[ -n "$token" ]] || skill_wrapper_die "$WRAPPER" "missing access token; pass --token or set ALOOK_ACCESS_TOKEN"
[[ -z "$name" || -n "$role" ]] || skill_wrapper_die "$WRAPPER" "--name requires --role"
target_family_count=0
[[ -n "${query:-}" ]] && ((target_family_count += 1))
[[ -n "$css" ]] && ((target_family_count += 1))
if [[ -n "$role" || -n "$name" ]]; then
  ((target_family_count += 1))
fi
[[ -n "$point_json" ]] && ((target_family_count += 1))
[[ "$target_family_count" -ge 1 ]] || skill_wrapper_die "$WRAPPER" "one of <query> --css --role [--name] --point-json is required"
[[ "$target_family_count" -le 1 ]] || skill_wrapper_die "$WRAPPER" "only one target family is allowed"

args=(command click --token "$token")
[[ -n "${query:-}" ]] && args+=(--string query "$query")
[[ -n "$css" ]] && args+=(--string css "$css")
if [[ -n "$role" || -n "$name" ]]; then
  [[ -n "$role" ]] && args+=(--string role "$role")
  [[ -n "$name" ]] && args+=(--string name "$name")
fi
[[ -n "$point_json" ]] && args+=(--json point "$point_json")
args+=(--string tabId "$tab_id")
[[ -n "$button" ]] && args+=(--string button "$button")
[[ -n "$click_count" ]] && args+=(--int clickCount "$click_count")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
