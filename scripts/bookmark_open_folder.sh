#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="bookmark_open_folder.sh"
USAGE="usage: bookmark_open_folder.sh <folderId> [--task-id ID] [--window-id ID] [--split-id ID] [--recursive] [--url-contains TEXT] [--limit N] [--token TOKEN]"
DESCRIPTION="Open bookmarks from a folder into the target context."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="${ALOOK_ACCESS_TOKEN:-${SKILL_ACCESS_TOKEN:-}}"
task_id=""
window_id=""
split_id=""
recursive="false"
url_contains=""
limit=""

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
shift_count=0
folder_id="${1:-}"
[[ -n "$folder_id" ]] || skill_wrapper_die "$WRAPPER" "missing required argument: <folderId>"
shift_count=1
(( shift_count > 0 )) && shift "$shift_count" || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      token="$2"
      shift 2
      ;;
    --task-id)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      task_id="$2"
      shift 2
      ;;
    --window-id)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      window_id="$2"
      shift 2
      ;;
    --split-id)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      split_id="$2"
      shift 2
      ;;
    --recursive)
      recursive="true"
      shift
      ;;
    --url-contains)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      url_contains="$2"
      shift 2
      ;;
    --limit)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      limit="$2"
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
[[ -n "$token" ]] || skill_wrapper_die "$WRAPPER" "missing access token; pass --token or set ALOOK_ACCESS_TOKEN"

args=(command bookmark_open_folder --token "$token")
[[ -n "$task_id" ]] && args+=(--string taskId "$task_id")
args+=(--string folderId "$folder_id")
[[ -n "$window_id" ]] && args+=(--string windowId "$window_id")
[[ -n "$split_id" ]] && args+=(--string splitId "$split_id")
[[ -n "$recursive" ]] && args+=(--bool recursive "$recursive")
[[ -n "$url_contains" ]] && args+=(--string urlContains "$url_contains")
[[ -n "$limit" ]] && args+=(--int limit "$limit")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
