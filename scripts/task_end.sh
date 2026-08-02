#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_wrapper_lib.sh"
WRAPPER="task_end.sh"
USAGE="usage: task_end.sh <taskId> [--cleanup] [--token TOKEN]"
DESCRIPTION="End a managed browser task and optionally clean its owned resources."

usage() {
  [[ -n "$DESCRIPTION" ]] && echo "# $DESCRIPTION" >&2
  echo "$USAGE" >&2
}

token="${ALOOK_ACCESS_TOKEN:-${SKILL_ACCESS_TOKEN:-}}"
cleanup="false"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
shift_count=0
task_id="${1:-}"
[[ -n "$task_id" ]] || skill_wrapper_die "$WRAPPER" "missing required argument: <taskId>"
shift_count=1
(( shift_count > 0 )) && shift "$shift_count" || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      skill_wrapper_require_value "$WRAPPER" "$1" "${2:-}"
      token="$2"
      shift 2
      ;;
    --cleanup)
      cleanup="true"
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

[[ -n "$token" ]] || skill_wrapper_die "$WRAPPER" "missing access token; pass --token or set ALOOK_ACCESS_TOKEN"

args=(command task_end --token "$token")
args+=(--string taskId "$task_id")
[[ -n "$cleanup" ]] && args+=(--bool cleanup "$cleanup")
exec "$SKILL_WRAPPER_CORE" "${args[@]}"
