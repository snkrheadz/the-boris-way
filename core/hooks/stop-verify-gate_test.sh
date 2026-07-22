#!/bin/bash
# Behavior tests for core/hooks/stop-verify-gate.sh (the stop-time closing-gate
# nudge). Discovered and run by scripts/validate.sh via the */hooks/*_test.sh
# glob — never enumerated by hand.
#
# The hook ALWAYS exits 0 — the signal is the presence or absence of the
# {"decision":"block"} JSON on stdout, so every case asserts on OUTPUT:
#   block         — verify.sh exists, edits in transcript, never ran → block
#   block-binary  — same, edit evidence among invalid-UTF8/NUL bytes → block
#   block-subedit — edits only in a sidecar subagent transcript      → block
#   quiet-active  — stop_hook_active=true (loop prevention)          → allow
#   quiet-nogate  — cwd has no scripts/verify.sh                     → allow
#   quiet-ran     — transcript has a "command":"…verify.sh" entry    → allow
#   quiet-subran  — verify.sh run only in a subagent transcript      → allow
#   quiet-noedit  — no Edit/Write/NotebookEdit tool call             → allow
#   quiet-nopath  — payload has no transcript_path                   → allow (fail-open)
#   quiet-nofile  — transcript_path points at a missing file         → allow (fail-open)
#   quiet-nojq    — jq unavailable on PATH                           → allow (fail-open)
# Every case additionally asserts exit code 0 (the hook never hard-fails).
#
# Exit 0 when every case passes; non-zero (listing the failed case) otherwise.

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/stop-verify-gate.sh"

PASS=0
FAIL=0
pass() {
    echo "  [pass] $1"
    PASS=$((PASS + 1))
}
fail() {
    echo "  [FAIL] $1"
    FAIL=$((FAIL + 1))
}

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# --- fixtures ----------------------------------------------------------------
# A repo that opted in (has scripts/verify.sh) and one that did not.
REPO="$TMP/repo"
mkdir -p "$REPO/scripts"
: > "$REPO/scripts/verify.sh"
NOGATE="$TMP/nogate"
mkdir -p "$NOGATE"

# Edits happened, verify.sh never ran.
EDITED="$TMP/edited.jsonl"
printf '%s\n' \
    '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"/x","old_string":"a","new_string":"b"}}]}}' \
    '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"git status"}}]}}' \
    > "$EDITED"

# Edits happened AND verify.sh was run as a command.
RAN="$TMP/ran.jsonl"
printf '%s\n' \
    '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Write","input":{"file_path":"/x","content":"c"}}]}}' \
    '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"bash scripts/verify.sh"}}]}}' \
    > "$RAN"

# No edits at all: read-only session.
NOEDIT="$TMP/noedit.jsonl"
printf '%s\n' \
    '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"git log"}}]}}' \
    > "$NOEDIT"

# Edit evidence embedded among invalid-UTF8/NUL bytes.
BINARY="$TMP/binary.jsonl"
{
    printf '\x00\xff\xfe garbage \x80\x81\n'
    printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"/x","old_string":"a","new_string":"b"}}]}}'
    printf '\x00\xc3\x28 more garbage\n'
} > "$BINARY"

# Edits only in a sidecar subagent transcript (delegated implementation).
SUBEDIT="$TMP/subedit.jsonl"
printf '%s\n' \
    '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"git status"}}]}}' \
    > "$SUBEDIT"
mkdir -p "$TMP/subedit/subagents"
printf '%s\n' \
    '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"/x","old_string":"a","new_string":"b"}}]}}' \
    > "$TMP/subedit/subagents/agent-e1.jsonl"

# Edits in main, verify.sh run only in a subagent transcript (delegated verify).
SUBRAN="$TMP/subran.jsonl"
printf '%s\n' \
    '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"/x","old_string":"a","new_string":"b"}}]}}' \
    > "$SUBRAN"
mkdir -p "$TMP/subran/subagents"
printf '%s\n' \
    '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"bash scripts/verify.sh"}}]}}' \
    > "$TMP/subran/subagents/agent-v1.jsonl"

# --- harness -----------------------------------------------------------------
payload() {
    # $1 = transcript_path ("" to omit the key), $2 = cwd, $3 = stop_hook_active
    if [[ -n "$1" ]]; then
        printf '{"session_id":"s","transcript_path":"%s","cwd":"%s","stop_hook_active":%s,"hook_event_name":"Stop"}' "$1" "$2" "$3"
    else
        printf '{"session_id":"s","cwd":"%s","stop_hook_active":%s,"hook_event_name":"Stop"}' "$2" "$3"
    fi
}

# run <case> <expect: block|quiet> <payload...>
run() {
    local case_name="$1" expect="$2" out rc
    shift 2
    out=$(printf '%s' "$*" | "$HOOK" 2>/dev/null)
    rc=$?
    if [[ $rc -ne 0 ]]; then
        fail "$case_name: exit code $rc (must always be 0)"
        return
    fi
    case "$expect" in
        block)
            if [[ "$out" == *'"decision": "block"'* ]]; then
                pass "$case_name"
            else
                fail "$case_name: expected block JSON on stdout, got: '$out'"
            fi
            ;;
        quiet)
            if [[ -z "$out" ]]; then
                pass "$case_name"
            else
                fail "$case_name: expected no output, got: '$out'"
            fi
            ;;
    esac
}

echo "stop-verify-gate.sh behavior tests"

run "block"         block "$(payload "$EDITED"  "$REPO"   false)"
run "block-binary"  block "$(payload "$BINARY"  "$REPO"   false)"
run "block-subedit" block "$(payload "$SUBEDIT" "$REPO"   false)"
run "quiet-active"  quiet "$(payload "$EDITED"  "$REPO"   true)"
run "quiet-nogate"  quiet "$(payload "$EDITED"  "$NOGATE" false)"
run "quiet-ran"     quiet "$(payload "$RAN"     "$REPO"   false)"
run "quiet-subran"  quiet "$(payload "$SUBRAN"  "$REPO"   false)"
run "quiet-noedit"  quiet "$(payload "$NOEDIT"  "$REPO"   false)"
run "quiet-nopath"  quiet "$(payload ""         "$REPO"   false)"
run "quiet-nofile"  quiet "$(payload "$TMP/absent.jsonl" "$REPO" false)"

# quiet-nojq: strip PATH so jq (and everything else) is unavailable → fail-open.
out=$(printf '%s' "$(payload "$EDITED" "$REPO" false)" | PATH="" "$HOOK" 2>/dev/null)
rc=$?
if [[ $rc -eq 0 && -z "$out" ]]; then
    pass "quiet-nojq"
else
    fail "quiet-nojq: rc=$rc out='$out'"
fi

echo "  → $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
