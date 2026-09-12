#!/usr/bin/env bash
# eval-init.sh — scaffold an eval suite into every LOCAL pack, in one pass.
#
# `claude plugin eval init` is per-plugin and cwd-relative: you normally run
# `cd eng && claude plugin eval init`. This does that for every pack the repo
# ships, so a new pack is never the one without evals.
#
# Interview vs template — the one thing to know before running this:
#   Bare `claude plugin eval init` is an INTERVIEW. Run from a terminal it
#   hosts one; run from inside a Claude Code session it prints the interview
#   for the session to conduct and writes nothing. Neither survives a loop —
#   eight packs would mean eight interleaved interviews. So this script uses
#   `--bare`, which writes the blank template (prompt.md + graders/criteria.md,
#   both TODO) non-interactively.
#
#   That means: this script scaffolds, it does not author. A real suite still
#   comes from `cd <pack> && claude plugin eval init` with a human in the loop,
#   one pack at a time. Treat what lands here as the placeholder that makes the
#   missing suite visible.
#
# Idempotent: a pack whose case directory already exists is skipped untouched,
# so hand-authored suites are never clobbered by a re-run.
#
# Packs come from disk (*/.claude-plugin/plugin.json), so a newly added pack is
# picked up automatically and the catalog's proxy entries — which have no local
# directory — are excluded for free.
#
# It never pilots a case: `claude plugin eval <pack>` loads the plugin and runs
# it on this machine as you, and that is a deliberate, per-pack decision.
#
# Usage: bash scripts/eval-init.sh [case-name] [pack ...]   (from the repo root)
#          case-name  name of the case directory (default: smoke). Omit it to
#                     pass packs straight through: `eval-init.sh eng pm`.
#          pack       limit to these packs (default: every local pack)

set -euo pipefail

cd "$(dirname "$0")/.."

created=0
skipped=0
fail=0
err()  { printf '\033[31mFAIL\033[0m %s\n' "$1" >&2; fail=$((fail + 1)); }
ok()   { printf '\033[32m  ok\033[0m %s\n' "$1"; }
skip() { printf '\033[33mskip\033[0m %s\n' "$1"; skipped=$((skipped + 1)); }

# `eval-init.sh eng` reads as "just the eng pack", not "a case named eng" —
# a bare pack name as the first arg takes that meaning.
case_name="smoke"
if [ $# -gt 0 ] && [ ! -f "$1/.claude-plugin/plugin.json" ]; then
  case_name="$1"
  shift
fi

if ! command -v claude >/dev/null 2>&1; then
  err "the 'claude' CLI is not on PATH — nothing to run"
  exit 1
fi

packs=("$@")
if [ ${#packs[@]} -eq 0 ]; then
  while IFS= read -r manifest; do
    packs+=("$(basename "$(dirname "$(dirname "$manifest")")")")
  done < <(find . -maxdepth 3 -path ./.git -prune -o -path './*/.claude-plugin/plugin.json' -print | sort)
fi

if [ ${#packs[@]} -eq 0 ]; then
  err "no local packs found (*/.claude-plugin/plugin.json)"
  exit 1
fi

echo "== claude plugin eval init --bare $case_name =="

for pack in "${packs[@]}"; do
  if [ ! -f "$pack/.claude-plugin/plugin.json" ]; then
    err "$pack — not a local pack (no .claude-plugin/plugin.json)"
    continue
  fi

  # The eval dir honours the manifest's experimental.evals, same as the CLI.
  eval_dir=$(sed -n 's/.*"evals"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$pack/.claude-plugin/plugin.json" | head -1)
  eval_dir="${eval_dir:-evals}"

  if [ -d "$pack/$eval_dir/$case_name" ]; then
    skip "$pack — $eval_dir/$case_name already exists"
    continue
  fi

  if out=$(cd "$pack" && claude plugin eval init --bare "$case_name" 2>&1); then
    ok "$pack — $out"
    created=$((created + 1))
  else
    err "$pack — $out"
  fi
done

printf '\n%d created, %d skipped, %d failed\n' "$created" "$skipped" "$fail"
echo "Next: fill in each evals/$case_name/prompt.md + graders/criteria.md,"
echo "  or re-author a pack properly with: cd <pack> && claude plugin eval init"
[ "$fail" -eq 0 ]
