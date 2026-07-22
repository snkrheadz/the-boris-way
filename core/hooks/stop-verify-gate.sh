#!/bin/bash
# Stop hook: block a session's stop ONCE when files were edited but the repo's
# closing-gate entrypoint (scripts/verify.sh) was never run.
#
# WHY (the auto-mode pairing): a permission mode's classifier guards INTENT
# while the session runs; nothing in the harness guards CORRECTNESS at the
# end. This hook is that missing half, as a convention: a repo opts in simply
# by having scripts/verify.sh at its root — repos without one never see it
# fire. The verify IMPLEMENTATION stays in each repo; this hook only owns the
# convention and the firing logic.
#
# The hook deliberately does NOT run verify.sh itself. A verify verdict is
# environment-dependent (entrypoints SKIP tool-dependent checks where tools
# are absent), and a Stop hook that ran a whole gate would stall every stop.
# Detection only: it asks Claude once, via the block reason, to run the gate
# and report honestly.
#
# Block-once: stop_hook_active is true when the session is already continuing
# because a Stop hook blocked — exit 0 then, so one extra turn is the ceiling
# and a loop is impossible.
#
# FAIL-OPEN, same governing principle as pre-tool-guard: every anomaly (jq
# missing, no transcript, unreadable transcript, grep error) exits 0 with no
# output. The block fires on exactly one positive condition: scripts/verify.sh
# exists AND the transcript (main or sidecar subagent) shows an Edit/Write/
# NotebookEdit tool call AND no evidence that verify.sh was run as a command.
#
# Edit evidence is a loose proxy ("name":"Edit|Write|NotebookEdit" anywhere in
# the JSONL): prose embedding that exact JSON shape can false-positive, but
# the cost is one nudge, and only in sessions that also never ran verify.sh.
# Bash-mediated edits (sed -i …) are NOT detected — a missed nudge fails open.
# Verify evidence is scoped to a "command" field naming verify.sh: the script
# is discussed as prose all over a normal session (docs edits, this very
# header), and matching prose would suppress the nudge permanently. A command
# that merely VIEWS the script (cat/grep/git log -- scripts/verify.sh) also
# suppresses — accepted: that error fails toward a missed nudge, never a block.
#
# Exit code is ALWAYS 0. The signal is the {"decision":"block"} JSON on stdout.

# Builtin read (no `cat` fork): keep the non-matching fast path cheap.
IFS= read -r -d '' input || true

# jq parses the payload; without it we can read nothing → allow.
command -v jq &> /dev/null || exit 0

# Loop prevention comes first: already continuing from a Stop-hook block.
[[ "$(jq -r '.stop_hook_active // false' <<< "$input" 2>/dev/null)" == "true" ]] && exit 0

# Convention check: the repo opts in by having scripts/verify.sh.
cwd=$(jq -r '.cwd // empty' <<< "$input" 2>/dev/null)
[[ -n "$cwd" ]] || cwd="$PWD"
[[ -f "$cwd/scripts/verify.sh" ]] || exit 0

# Without a transcript we cannot prove an edit happened → allow.
transcript=$(jq -r '.transcript_path // empty' <<< "$input" 2>/dev/null)
[[ -n "$transcript" && -f "$transcript" ]] || exit 0

# Main transcript + sidecar subagent transcripts (delegated edits and
# delegated verify runs record their tool calls there, not in the main file).
files=("$transcript")
subdir="${transcript%.jsonl}/subagents"
if [[ -d "$subdir" ]]; then
    for f in "$subdir"/*.jsonl; do
        [[ -f "$f" ]] && files+=("$f")
    done
fi

# LC_ALL=C + -a: real transcripts carry invalid-UTF8/NUL bytes on which BSD
# grep otherwise errors or takes the binary shortcut.
EDIT_PATTERN='"name"[[:space:]]*:[[:space:]]*"(Edit|Write|NotebookEdit)"'
VERIFY_PATTERN='"command"[[:space:]]*:[[:space:]]*"[^"]*verify\.sh'

edited=0
for f in "${files[@]}"; do
    if LC_ALL=C grep -a -Eq "$EDIT_PATTERN" "$f" 2>/dev/null; then
        edited=1
        break
    fi
done
[[ $edited -eq 1 ]] || exit 0

for f in "${files[@]}"; do
    LC_ALL=C grep -a -Eq "$VERIFY_PATTERN" "$f" 2>/dev/null
    rc=$?
    [[ $rc -eq 0 ]] && exit 0   # verify.sh ran → nothing to nudge
    [[ $rc -ge 2 ]] && exit 0   # grep error: cannot prove absence → allow
done

cat << 'JSON'
{"decision": "block", "reason": "Files were edited this session but the repo's closing gate (scripts/verify.sh) has not been run. Run `bash scripts/verify.sh`, report each check's PASS/FAIL/SKIP honestly (a SKIP is not a PASS), fix any FAIL, then stop. If the gate cannot run in this environment, say so explicitly and stop."}
JSON
exit 0
