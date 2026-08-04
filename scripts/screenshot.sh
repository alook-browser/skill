#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="screenshot.sh"
USAGE="usage:
  screenshot.sh <tabId> [--format png|jpeg] [--quality N] [--scale N] [--token TOKEN]
  screenshot.sh <tabId> <query> [--format png|jpeg] [--quality N] [--scale N] [--token TOKEN]
  screenshot.sh <tabId> --css CSS [--format png|jpeg] [--quality N] [--scale N] [--token TOKEN]
  screenshot.sh <tabId> --role ROLE [--name NAME] [--format png|jpeg] [--quality N] [--scale N] [--token TOKEN]
  screenshot.sh <tabId> --point-json JSON [--format png|jpeg] [--quality N] [--scale N] [--token TOKEN]"
DESCRIPTION="Capture the current viewport or one matched visible target."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="$(skill_wrapper_default_access_token)"
css=""
role=""
name=""
point_json=""
format=""
quality=""
scale=""

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
    --format)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      format="$2"
      shift 2
      ;;
    --quality)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      quality="$2"
      shift 2
      ;;
    --scale)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      scale="$2"
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

[[ -z "$quality" || "$quality" =~ ^-?[0-9]+$ ]] || skill_wrapper_die "$WRAPPER" "--quality must be an integer"
[[ -z "$scale" || "$scale" =~ ^-?([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]] || skill_wrapper_die "$WRAPPER" "--scale must be a number"
[[ -n "$token" ]] || skill_wrapper_die "$WRAPPER" "missing access token; pass --token or run access.sh, then access_confirm.sh"
[[ -z "$name" || -n "$role" ]] || skill_wrapper_die "$WRAPPER" "--name requires --role"
target_family_count=0
[[ -n "${query:-}" ]] && ((target_family_count += 1))
[[ -n "$css" ]] && ((target_family_count += 1))
if [[ -n "$role" || -n "$name" ]]; then
  ((target_family_count += 1))
fi
[[ -n "$point_json" ]] && ((target_family_count += 1))
[[ "$target_family_count" -le 1 ]] || skill_wrapper_die "$WRAPPER" "only one target family is allowed"

args=(command screenshot --token "$token")
[[ -n "${query:-}" ]] && args+=(--string query "$query")
[[ -n "$css" ]] && args+=(--string css "$css")
if [[ -n "$role" || -n "$name" ]]; then
  [[ -n "$role" ]] && args+=(--string role "$role")
  [[ -n "$name" ]] && args+=(--string name "$name")
fi
[[ -n "$point_json" ]] && args+=(--json point "$point_json")
args+=(--string tabId "$tab_id")
[[ -n "$format" ]] && args+=(--string format "$format")
[[ -n "$quality" ]] && args+=(--int quality "$quality")
[[ -n "$scale" ]] && args+=(--json scale "$scale")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
