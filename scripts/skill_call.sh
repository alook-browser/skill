#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${SKILL_BASE_URL:-http://127.0.0.1:15729}"
DEFAULT_TOKEN="${ALOOK_ACCESS_TOKEN:-${SKILL_ACCESS_TOKEN:-}}"

emit_local_error() {
  local code="${1:-operation_failed}"
  local message="${2:-Skill command failed}"
  local retryable="${3:-false}"
  local hint="${4:-Check the command and retry}"
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$code" "$message" "$retryable" "$hint" <<'PY'
import json
import sys

code, message, retryable, hint = sys.argv[1:]
print(json.dumps({
    "ok": False,
    "error": {
        "code": code,
        "message": message,
        "retryable": retryable == "true",
        "hint": hint,
    },
}, ensure_ascii=False, separators=(",", ":")))
PY
  else
    /usr/bin/osascript -l JavaScript - "$code" "$message" "$retryable" "$hint" <<'JXA'
function run(argv) {
  return JSON.stringify({
    ok: false,
    error: {
      code: argv[0],
      message: argv[1],
      retryable: argv[2] === "true",
      hint: argv[3]
    }
  });
}
JXA
  fi
  return 1
}

die() {
  emit_local_error "invalid_params" "$*" false "Fix the command arguments" || true
  exit 1
}

require_value() {
  local flag="$1"
  local value="${2:-}"
  [[ -n "$value" ]] || die "missing value for ${flag}"
}

normalize_bool() {
  local value="${1:-}"
  local lowered
  lowered=$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')
  case "$lowered" in
    true|1|yes|on) printf 'true' ;;
    false|0|no|off) printf 'false' ;;
    *) die "invalid bool value: ${value}" ;;
  esac
}

json_from_triplets() {
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$@" <<'PY'
import json, sys
args = sys.argv[1:]
if len(args) % 3 != 0:
    raise SystemExit("field triplets must be type key value")
payload = {}
for index in range(0, len(args), 3):
    field_type, key, value = args[index:index + 3]
    if field_type == "string":
        payload[key] = value
    elif field_type == "int":
        try:
            payload[key] = int(value)
        except ValueError:
            raise SystemExit("invalid integer value for %s: %s" % (key, value))
    elif field_type == "bool":
        lowered = value.lower()
        if lowered in ("true", "1", "yes", "on"):
            payload[key] = True
        elif lowered in ("false", "0", "no", "off"):
            payload[key] = False
        else:
            raise SystemExit("invalid bool value: %s" % value)
    elif field_type == "json":
        try:
            payload[key] = json.loads(value)
        except ValueError:
            raise SystemExit("invalid JSON value for %s" % key)
    else:
        raise SystemExit("unsupported field type: %s" % field_type)
print(json.dumps(payload, ensure_ascii=False))
PY
    return
  fi
  /usr/bin/osascript -l JavaScript - "$@" <<'JXA'
function parseBool(value) {
  var lowered = String(value).toLowerCase();
  if (lowered === "true" || lowered === "1" || lowered === "yes" || lowered === "on") {
    return true;
  }
  if (lowered === "false" || lowered === "0" || lowered === "no" || lowered === "off") {
    return false;
  }
  throw new Error("invalid bool value: " + value);
}

function run(argv) {
  if (argv.length % 3 !== 0) {
    throw new Error("field triplets must be type key value");
  }
  var payload = {};
  for (var index = 0; index < argv.length; index += 3) {
    var fieldType = argv[index];
    var key = argv[index + 1];
    var value = argv[index + 2];
    if (fieldType === "string") {
      payload[key] = value;
    } else if (fieldType === "int") {
      if (!/^-?[0-9]+$/.test(value)) {
        throw new Error("invalid integer value for " + key + ": " + value);
      }
      payload[key] = parseInt(value, 10);
    } else if (fieldType === "bool") {
      payload[key] = parseBool(value);
    } else if (fieldType === "json") {
      payload[key] = JSON.parse(value);
    } else {
      throw new Error("unsupported field type: " + fieldType);
    }
  }
  return JSON.stringify(payload);
}
JXA
}

emit_json_and_status() {
  local response="${1:-}"
  local status
  if command -v python3 >/dev/null 2>&1; then
    status=$(printf '%s\n' "$response" | python3 -c '
import json, sys
try:
    payload = json.load(sys.stdin)
except Exception:
    print("invalid")
else:
    if not isinstance(payload, dict):
        print("invalid")
    else:
        print("0" if payload.get("ok") is not False else "1")
')
  else
    status=$(printf '%s\n' "$response" | /usr/bin/osascript -l JavaScript -e 'ObjC.import("Foundation"); var data = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile; var input = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js; try { var payload = JSON.parse(input || "{}"); payload && !Array.isArray(payload) && typeof payload === "object" ? (payload.ok === false ? "1" : "0") : "invalid"; } catch (error) { "invalid"; }'
)
  fi
  if [[ "$status" == "invalid" ]]; then
    emit_local_error "operation_failed" "Skill server returned an invalid response" false "Check the target state before deciding whether to retry; restart Debug Alook if the server is unhealthy"
    return
  fi
  printf '%s\n' "$response"
  [[ "$status" == "0" ]]
}

emit_post_transport_error() {
  local curl_status="${1:-1}"
  case "$curl_status" in
    5|6|7)
      emit_local_error "operation_failed" "Cannot reach the Skill server" true "Start Debug Alook and retry the command"
      ;;
    *)
      emit_local_error "operation_failed" "Skill server request failed" false "Check the target state before deciding whether to retry"
      ;;
  esac
}

post_json() {
  local path="${1:?path required}"
  local token="${2:-}"
  local payload="${3:?payload required}"
  local response curl_status

  if [[ -n "$token" ]]; then
    if response=$(curl -sS -X POST "${BASE_URL}${path}" \
      -H "Content-Type: application/json" \
      -H "Access-Token: ${token}" \
      --data-binary "$payload" 2>&1); then
      :
    else
      curl_status=$?
      emit_post_transport_error "$curl_status" || true
      return 1
    fi
  else
    if response=$(curl -sS -X POST "${BASE_URL}${path}" \
      -H "Content-Type: application/json" \
      --data-binary "$payload" 2>&1); then
      :
    else
      curl_status=$?
      emit_post_transport_error "$curl_status" || true
      return 1
    fi
  fi
  emit_json_and_status "$response"
}

post_triplets() {
  local path="${1:?path required}"
  local token="${2:-}"
  shift 2
  local payload
  if ! payload=$(json_from_triplets "$@" 2>&1); then
    emit_local_error "invalid_params" "$payload" false "Fix the command arguments"
    return
  fi
  post_json "$path" "$token" "$payload"
}

print_usage() {
  cat <<'EOF'
usage:
  bash scripts/skill_call.sh health
  bash scripts/skill_call.sh access --agent-name NAME
  bash scripts/skill_call.sh access-confirm --challenge-id ID
  bash scripts/skill_call.sh command ACTION [--token TOKEN] [--string KEY VALUE] [--int KEY VALUE] [--bool KEY VALUE] [--json KEY JSON] [--string-file KEY FILE] [--stdin-string KEY]
env:
  SKILL_BASE_URL defaults to http://127.0.0.1:15729
  ALOOK_ACCESS_TOKEN or SKILL_ACCESS_TOKEN can provide default token
EOF
}

command_subcommand() {
  local action="${1:-}"
  [[ -n "$action" ]] || die "command requires ACTION"
  action="${action//-/_}"
  shift || true

  local token="$DEFAULT_TOKEN"
  local -a fields=()
  fields+=(string action "$action")

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --token)
        require_value "$1" "${2:-}"
        token="$2"
        shift 2
        ;;
      --string)
        require_value "$1" "${2:-}"
        require_value "$1" "${3:-}"
        fields+=(string "$2" "$3")
        shift 3
        ;;
      --int)
        require_value "$1" "${2:-}"
        require_value "$1" "${3:-}"
        fields+=(int "$2" "$3")
        shift 3
        ;;
      --bool)
        require_value "$1" "${2:-}"
        require_value "$1" "${3:-}"
        fields+=(bool "$2" "$(normalize_bool "$3")")
        shift 3
        ;;
      --json)
        require_value "$1" "${2:-}"
        require_value "$1" "${3:-}"
        fields+=(json "$2" "$3")
        shift 3
        ;;
      --string-file)
        require_value "$1" "${2:-}"
        require_value "$1" "${3:-}"
        [[ -f "$3" ]] || die "file not found: $3"
        fields+=(string "$2" "$(cat "$3")")
        shift 3
        ;;
      --stdin-string)
        require_value "$1" "${2:-}"
        [[ -t 0 ]] && die "--stdin-string requires piped stdin"
        fields+=(string "$2" "$(cat)")
        shift 2
        ;;
      --help|-h)
        print_usage
        exit 0
        ;;
      *)
        die "unknown option for command: $1"
        ;;
    esac
  done

  [[ -n "$token" ]] || die "missing access token; pass --token or set ALOOK_ACCESS_TOKEN"
  post_triplets "/command" "$token" "${fields[@]}"
}

subcommand_access() {
  local agent_name=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --agent-name)
        require_value "$1" "${2:-}"
        agent_name="$2"
        shift 2
        ;;
      --help|-h)
        print_usage
        exit 0
        ;;
      *)
        die "unknown option for access: $1"
        ;;
    esac
  done
  [[ -n "$agent_name" ]] || die "access requires --agent-name"
  post_triplets "/access" "" string agentName "$agent_name"
}

subcommand_access_confirm() {
  local challenge_id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --challenge-id)
        require_value "$1" "${2:-}"
        challenge_id="$2"
        shift 2
        ;;
      --help|-h)
        print_usage
        exit 0
        ;;
      *)
        die "unknown option for access-confirm: $1"
        ;;
    esac
  done
  [[ -n "$challenge_id" ]] || die "access-confirm requires --challenge-id"
  post_triplets "/access/confirm" "" string challengeId "$challenge_id"
}

main() {
  local subcommand="${1:-}"
  [[ -n "$subcommand" ]] || {
    print_usage
    exit 1
  }
  shift || true

  case "$subcommand" in
    health)
      local response
      if ! response=$(curl -sS "${BASE_URL}/health" 2>&1); then
        emit_local_error "operation_failed" "Cannot reach the Skill server" true "Start Debug Alook and retry health.sh"
        return
      fi
      emit_json_and_status "$response"
      ;;
    access)
      subcommand_access "$@"
      ;;
    access-confirm)
      subcommand_access_confirm "$@"
      ;;
    command)
      command_subcommand "$@"
      ;;
    --help|-h|help)
      print_usage
      ;;
    *)
      die "unknown subcommand: ${subcommand}"
      ;;
  esac
}

main "$@"
