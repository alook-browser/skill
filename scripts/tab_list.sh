#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="tab_list.sh"
USAGE="usage: tab_list.sh [--task-id ID] [--window-id ID] [--split-id ID] [--token TOKEN]"
DESCRIPTION="List tabs globally, optionally filtered by task, window, or split."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="${ALOOK_ACCESS_TOKEN:-${SKILL_ACCESS_TOKEN:-}}"
task_id=""
window_id=""
split_id=""

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

args=(command tab_list --token "$token")
[[ -n "$task_id" ]] && args+=(--string taskId "$task_id")
[[ -n "$window_id" ]] && args+=(--string windowId "$window_id")
[[ -n "$split_id" ]] && args+=(--string splitId "$split_id")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
