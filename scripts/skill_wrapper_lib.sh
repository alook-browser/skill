#!/usr/bin/env bash

SKILL_WRAPPER_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKILL_WRAPPER_CORE="$SKILL_WRAPPER_DIR/skill_call.sh"
SKILL_WRAPPER_ROOT="$(cd -- "$SKILL_WRAPPER_DIR/.." && pwd)"
SKILL_WRAPPER_COLLECTION_DIR="$(cd -- "$SKILL_WRAPPER_ROOT/.." && pwd)"
SKILL_ACCESS_TOKEN_FILE="${SKILL_ACCESS_TOKEN_FILE:-$SKILL_WRAPPER_COLLECTION_DIR/.alook-access-token}"

skill_wrapper_read_saved_access_token() {
  local token=""
  [[ -r "$SKILL_ACCESS_TOKEN_FILE" ]] || return 0
  IFS= read -r token < "$SKILL_ACCESS_TOKEN_FILE" || true
  printf '%s' "$token"
}

skill_wrapper_default_access_token() {
  skill_wrapper_read_saved_access_token
}

skill_wrapper_save_access_token() {
  local token="${1:-}"
  local temporary_file="${SKILL_ACCESS_TOKEN_FILE}.tmp.$$"
  [[ -n "$token" ]] || return 1
  if ! (umask 077 && printf '%s\n' "$token" > "$temporary_file"); then
    rm -f "$temporary_file"
    return 1
  fi
  if ! mv -f "$temporary_file" "$SKILL_ACCESS_TOKEN_FILE"; then
    rm -f "$temporary_file"
    return 1
  fi
}

skill_wrapper_clear_saved_access_token_if_matches() {
  local token="${1:-}"
  local saved_token
  saved_token="$(skill_wrapper_read_saved_access_token)"
  [[ -n "$saved_token" && "$saved_token" == "$token" ]] || return 0
  rm -f "$SKILL_ACCESS_TOKEN_FILE"
}

skill_wrapper_die() {
  local wrapper="${1:-skill_wrapper}"
  shift || true
  local message="$*"
  local code="invalid_params"
  local hint="${USAGE:-Fix the command arguments}"
  if [[ "$message" == missing\ access\ token* ]]; then
    code="missing_access_token"
    message="Missing access token"
    hint="Run access.sh, then access_confirm.sh"
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$code" "$message" "$hint" <<'PY'
import json
import sys

code, message, hint = sys.argv[1], sys.argv[2], sys.argv[3]
payload = {
    "ok": False,
    "error": {
        "code": code,
        "message": message,
        "retryable": False,
        "hint": hint,
    },
}
print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
PY
  else
    /usr/bin/osascript -l JavaScript - "$code" "$message" "$hint" <<'JXA'
function run(argv) {
  return JSON.stringify({
    ok: false,
    error: {
      code: argv[0],
      message: argv[1],
      retryable: false,
      hint: argv[2]
    }
  });
}
JXA
  fi
  exit 1
}

skill_wrapper_require_value() {
  local wrapper="$1"
  local flag="$2"
  local value="${3:-}"
  [[ -n "$value" ]] || skill_wrapper_die "$wrapper" "missing value for ${flag}"
}

skill_wrapper_json_string_array_from_csv() {
  local csv="${1:-}"
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$csv" <<'PY'
import json, sys
items = [part.strip() for part in sys.argv[1].split(",") if part.strip()]
print(json.dumps(items, ensure_ascii=False))
PY
    return
  fi
  /usr/bin/osascript -l JavaScript - "$csv" <<'JXA'
function run(argv) {
  var raw = argv[0] || "";
  var items = raw.split(",").map(function (part) { return part.trim(); }).filter(function (part) { return part.length > 0; });
  return JSON.stringify(items);
}
JXA
}

skill_wrapper_json_string_array_from_lines() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json, sys; items = [line.rstrip("\n") for line in sys.stdin]; print(json.dumps(items, ensure_ascii=False))'
    return
  fi
  /usr/bin/osascript -l JavaScript -e 'ObjC.import("Foundation"); function run() { var stdin = $.NSFileHandle.fileHandleWithStandardInput; var data = stdin.readDataToEndOfFile; var str = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding); var text = ObjC.unwrap(str || ""); var items = text.split(/\n/); if (items.length > 0 && items[items.length - 1] === "") { items.pop(); } return JSON.stringify(items); }'
}
