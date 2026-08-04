#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="bookmark_find.sh"
USAGE="usage: bookmark_find.sh (<query> | --text-stdin) [--kind item|folder|any] [--limit N] [--token TOKEN]"
DESCRIPTION="Search bookmarks by query text."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="$(skill_wrapper_default_access_token)"
kind=""
limit=""
query=""
text_source=""

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
shift_count=0
query=""
if [[ $# -ge 1 && "${1:-}" != --* ]]; then
  query="${1}"
  text_source="arg"
  shift_count=1
fi
(( shift_count > 0 )) && shift "$shift_count" || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      token="$2"
      shift 2
      ;;
    --kind)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      kind="$2"
      shift 2
      ;;
    --limit)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      limit="$2"
      shift 2
      ;;
    --text-stdin)
      [[ -z "$text_source" ]] || skill_wrapper_die "$WRAPPER" "only one text input source is allowed"
      [[ -t 0 ]] && skill_wrapper_die "$WRAPPER" "--text-stdin requires piped stdin"
      query="$(cat)"
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

[[ -z "$limit" || "$limit" =~ ^-?[0-9]+$ ]] || skill_wrapper_die "$WRAPPER" "--limit must be an integer"
[[ -n "$token" ]] || skill_wrapper_die "$WRAPPER" "missing access token; pass --token or run access.sh, then access_confirm.sh"
[[ -n "$query" ]] || skill_wrapper_die "$WRAPPER" "query is required"

args=(command bookmark_find --token "$token")
args+=(--string query "$query")
[[ -n "$kind" ]] && args+=(--string kind "$kind")
[[ -n "$limit" ]] && args+=(--int limit "$limit")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
