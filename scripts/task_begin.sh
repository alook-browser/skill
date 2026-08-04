#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="task_begin.sh"
USAGE="usage: task_begin.sh [--token TOKEN]"
DESCRIPTION="Start a new managed browser task."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="$(skill_wrapper_default_access_token)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      token="$2"
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

args=(command task_begin --token "$token")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
