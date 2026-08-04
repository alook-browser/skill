#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="wait.sh"
USAGE="usage:
  wait.sh <tabId> <query> [--timeout MS] [--mode exists|visible|text|count|enabled|disabled|removed|textstable] [--text TEXT | --text-file FILE | --text-stdin] [--count N] [--stable-time MS] [--token TOKEN]
  wait.sh <tabId> --css CSS [--timeout MS] [--mode exists|visible|text|count|enabled|disabled|removed|textstable] [--text TEXT | --text-file FILE | --text-stdin] [--count N] [--stable-time MS] [--token TOKEN]
  wait.sh <tabId> --role ROLE [--name NAME] [--timeout MS] [--mode exists|visible|text|count|enabled|disabled|removed|textstable] [--text TEXT | --text-file FILE | --text-stdin] [--count N] [--stable-time MS] [--token TOKEN]"
DESCRIPTION="Wait until one target condition becomes true."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="$(skill_wrapper_default_access_token)"
css=""
role=""
name=""
point_json=""
timeout=""
mode=""
count=""
stable_time=""
wait_text=""
text_source=""

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
    --timeout)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      timeout="$2"
      shift 2
      ;;
    --mode)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      mode="$2"
      shift 2
      ;;
    --count)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      count="$2"
      shift 2
      ;;
    --stable-time)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      stable_time="$2"
      shift 2
      ;;
    --text)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      [[ -z "$text_source" ]] || skill_wrapper_die "$WRAPPER" "only one text input source is allowed"
      wait_text="$2"
      text_source="arg"
      shift 2
      ;;
    --text-file)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      [[ -z "$text_source" ]] || skill_wrapper_die "$WRAPPER" "only one text input source is allowed"
      [[ -f "$2" ]] || skill_wrapper_die "$WRAPPER" "file not found: $2"
      wait_text="$(cat "$2")"
      text_source="file"
      shift 2
      ;;
    --text-stdin)
      [[ -z "$text_source" ]] || skill_wrapper_die "$WRAPPER" "only one text input source is allowed"
      [[ -t 0 ]] && skill_wrapper_die "$WRAPPER" "--text-stdin requires piped stdin"
      wait_text="$(cat)"
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

[[ -z "$timeout" || "$timeout" =~ ^-?[0-9]+$ ]] || skill_wrapper_die "$WRAPPER" "--timeout must be an integer"
[[ -z "$count" || "$count" =~ ^-?[0-9]+$ ]] || skill_wrapper_die "$WRAPPER" "--count must be an integer"
[[ -z "$stable_time" || "$stable_time" =~ ^-?[0-9]+$ ]] || skill_wrapper_die "$WRAPPER" "--stable-time must be an integer"
[[ -n "$token" ]] || skill_wrapper_die "$WRAPPER" "missing access token; pass --token or run access.sh, then access_confirm.sh"
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

args=(command wait_for --token "$token")
[[ -n "${query:-}" ]] && args+=(--string query "$query")
[[ -n "$css" ]] && args+=(--string css "$css")
if [[ -n "$role" || -n "$name" ]]; then
  [[ -n "$role" ]] && args+=(--string role "$role")
  [[ -n "$name" ]] && args+=(--string name "$name")
fi
args+=(--string tabId "$tab_id")
[[ -n "$timeout" ]] && args+=(--int timeout "$timeout")
[[ -n "$mode" ]] && args+=(--string mode "$mode")
[[ -n "$wait_text" ]] && args+=(--string text "$wait_text")
[[ -n "$count" ]] && args+=(--int count "$count")
[[ -n "$stable_time" ]] && args+=(--int stableTime "$stable_time")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
