#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="input.sh"
USAGE="usage:
  input.sh <tabId> <query> (--text TEXT | --text-file FILE | --text-stdin) [--token TOKEN]
  input.sh <tabId> --css CSS (--text TEXT | --text-file FILE | --text-stdin) [--token TOKEN]
  input.sh <tabId> --role ROLE [--name NAME] (--text TEXT | --text-file FILE | --text-stdin) [--token TOKEN]"
DESCRIPTION="Clear one editable target and type text into it."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="$(skill_wrapper_default_access_token)"
css=""
role=""
name=""
point_json=""
input_text=""
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
    --text)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      [[ -z "$text_source" ]] || skill_wrapper_die "$WRAPPER" "only one text input source is allowed"
      input_text="$2"
      text_source="arg"
      shift 2
      ;;
    --text-file)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      [[ -z "$text_source" ]] || skill_wrapper_die "$WRAPPER" "only one text input source is allowed"
      [[ -f "$2" ]] || skill_wrapper_die "$WRAPPER" "file not found: $2"
      input_text="$(cat "$2")"
      text_source="file"
      shift 2
      ;;
    --text-stdin)
      [[ -z "$text_source" ]] || skill_wrapper_die "$WRAPPER" "only one text input source is allowed"
      [[ -t 0 ]] && skill_wrapper_die "$WRAPPER" "--text-stdin requires piped stdin"
      input_text="$(cat)"
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
[[ -n "$text_source" ]] || skill_wrapper_die "$WRAPPER" "one of --text --text-file --text-stdin is required"

args=(command type --token "$token")
[[ -n "${query:-}" ]] && args+=(--string query "$query")
[[ -n "$css" ]] && args+=(--string css "$css")
if [[ -n "$role" || -n "$name" ]]; then
  [[ -n "$role" ]] && args+=(--string role "$role")
  [[ -n "$name" ]] && args+=(--string name "$name")
fi
args+=(--string tabId "$tab_id")
[[ -n "$input_text" ]] || skill_wrapper_die "$WRAPPER" "text is required"
args+=(--string text "$input_text")
args+=(--bool clear true)
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
