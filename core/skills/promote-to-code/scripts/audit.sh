#!/usr/bin/env bash
# audit.sh — deterministic detection layer for the promote-to-code skill.
#
# Boris Cherny's thesis: encode domain knowledge into infrastructure. Don't
# re-solve the same problem in tokens every run — turn the decision into code
# once and automate it forever. This script is the *code* half of that split:
# detecting which prose rules in a repo's CLAUDE.md are candidates for
# promotion into an enforcement mechanism (hook / CI / verify script) is a
# deterministic job, so a script does it. The MODEL (SKILL.md) only makes the
# promotion JUDGEMENT on the candidates this emits.
#
# Read-only: it never writes to the target repo. Argument $1 = target repo
# path (default: current directory).
#
# Output contract (two parts, in order):
#   1. Human summary — one line per check: PASS / FAIL / SKIP / WARN + reason.
#      SKIP always names *why* (a missing tool or absent input), never a silent
#      pass. Modelled on laptop repo scripts/verify.sh.
#   2. A literal line "---CANDIDATES---", then TSV rows for the skill to judge:
#         type<TAB>file<TAB>line<TAB>excerpt
#      type ∈ {C1,C2,C4,C5}. file is relative to the repo root.
#
# Exit code: 1 if any check FAILed (a broken invariant — an expired rule or a
# broken wired hook), else 0. WARN and SKIP do not fail the run: WARN marks
# judgement-call candidates (the skill decides), SKIP marks inapplicable checks.
#
# Checks:
#   C1 expired rules   — CLAUDE.md/.claude *.md lines pairing a date with a
#                        delete/remove/消せ/直ったら intent. >90d → FAIL,
#                        ≤90d → WARN. (hard invariant: a self-dated rule that
#                        outlived its own deadline is rot.)
#   C2 double bookkeeping — prose that names a hook/script already wired in
#                        settings.json: promoted, but the prose was never
#                        removed (a move-semantics violation). WARN.
#   C3 REVIEW.md       — present at repo root? Absent .github (no PR flow)
#                        → SKIP; present + REVIEW.md → PASS; present + missing
#                        → WARN (the normal pre-Phase-D input state).
#   C4 rule candidates — imperative prose (must/never/always/必ず/禁止/…).
#                        WARN only; never FAIL — the judgement is the skill's.
#   C5 gate/CI parity  — gate/verify/check commands in CLAUDE.md code fences
#                        that never appear in .github/workflows. No CI → SKIP.
#                        WARN.
#   C6 hooks health    — every hook script wired in settings.json exists, is
#                        executable, and (if shellcheck is present) passes it.
#                        No settings/hooks → SKIP; a broken wired hook → FAIL.

set -uo pipefail

# ── target repo (read-only) ─────────────────────────────────────────────────
REPO_ARG="${1:-$PWD}"
if ! REPO="$(cd "$REPO_ARG" 2>/dev/null && pwd)"; then
  echo "audit.sh: cannot enter target repo '$REPO_ARG'" >&2
  exit 2
fi

# ── result accumulation (verify.sh pattern) ─────────────────────────────────
R_NAME=()
R_STATUS=()
R_DETAIL=()
record() {
  R_NAME+=("$1")
  R_STATUS+=("$2")
  R_DETAIL+=("$3")
}

# ── candidate accumulation (the TSV payload) ────────────────────────────────
CAND=()
add_cand() {
  # $1=type $2=abs-file $3=line $4=excerpt. File is stored repo-relative and
  # the excerpt is flattened (tabs→spaces, clipped) so it can't break the TSV.
  local rel exc
  rel="${2#"$REPO"/}"
  exc="$(printf '%s' "$4" | tr '\t\r\n' '   ' | cut -c1-140)"
  CAND+=("$1"$'\t'"$rel"$'\t'"$3"$'\t'"$exc")
}

# ── prose extraction ────────────────────────────────────────────────────────
# Emit "lineno:content" for PROSE lines only: fenced code blocks, table rows,
# and tree-diagram lines are documentation shape, not rules. Scanning them is
# what made C2 flag every file-map mention of a wired script (10/10 false
# positives on the dogfood target); rule prose never lives in those shapes.
prose_lines() {
  awk '
    /^[[:space:]]*```/ { infence = !infence; next }
    infence            { next }
    /^[[:space:]]*\|/  { next }
    /[├└│]/            { next }
    { printf "%d:%s\n", NR, $0 }
  ' "$1" 2>/dev/null
}

# ── the markdown surface scanned by C1/C2/C4 ────────────────────────────────
# Root CLAUDE.md plus every *.md under .claude/. Nothing else is prose-rule
# territory.
MD_FILES=()
[ -f "$REPO/CLAUDE.md" ] && MD_FILES+=("$REPO/CLAUDE.md")
# claude/CLAUDE.md is the dotfiles-managed source of the global ~/.claude/CLAUDE.md
# (same reason settings discovery below includes claude/settings.json) — a real
# CLAUDE.md, just parked in a subdir. Include it so a dotfiles repo's rules are
# visible to the audit.
[ -f "$REPO/claude/CLAUDE.md" ] && MD_FILES+=("$REPO/claude/CLAUDE.md")
if [ -d "$REPO/.claude" ]; then
  # Prune agent worktrees (a nested checkout of the whole repo, left by a prior
  # Claude Code session — its duplicated CLAUDE.md/README would multiply every
  # finding) and vendored/VCS dirs.
  while IFS= read -r f; do MD_FILES+=("$f"); done \
    < <(find "$REPO/.claude" \
          \( -type d \( -name worktrees -o -name .git -o -name node_modules \) -prune \) \
          -o \( -name '*.md' -type f -print \) 2>/dev/null | sort)
fi

# ── settings.json discovery ─────────────────────────────────────────────────
# Generic layouts keep it under .claude/; the laptop repo (this skill's
# dogfood target, tasks #4/#5) keeps managed config at claude/settings.json.
# Search all four so a miss is a named SKIP, never a silent clean pass.
SETTINGS_SEARCHED=(
  "$REPO/.claude/settings.json"
  "$REPO/.claude/settings.local.json"
  "$REPO/settings.json"
  "$REPO/claude/settings.json"
)
SETTINGS_FILES=()
for s in "${SETTINGS_SEARCHED[@]}"; do
  [ -f "$s" ] && SETTINGS_FILES+=("$s")
done

# ── date → epoch (GNU date, then BSD date); nonzero return on parse failure ──
to_epoch() {
  local d="$1" e
  if e="$(date -d "$d" +%s 2>/dev/null)"; then printf '%s' "$e"; return 0; fi
  if e="$(date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null)"; then printf '%s' "$e"; return 0; fi
  return 1
}

NOW="$(date +%s)"

# ── C1 — expired dated rules ────────────────────────────────────────────────
check_c1() {
  if [ "${#MD_FILES[@]}" -eq 0 ]; then
    record "C1 expired-rules" "SKIP" "no CLAUDE.md or .claude/*.md to scan"
    return
  fi
  local kw='delete|remove|消せ|消す|削除|直ったら'
  local fails=0 warns=0 f line lineno content dt epoch age
  for f in "${MD_FILES[@]}"; do
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      lineno="${line%%:*}"
      content="${line#*:}"
      # Require a date token on the same line; skip the line if none.
      dt="$(printf '%s' "$content" | grep -oE '[0-9]{4}-[0-9]{2}(-[0-9]{2})?' | head -1)"
      [ -n "$dt" ] || continue
      case "$dt" in
        *-*-*) : ;;          # already YYYY-MM-DD
        *) dt="$dt-01" ;;    # YYYY-MM → first of month
      esac
      # A date we cannot parse must skip the line, not fall through to age 0
      # (which would spuriously FAIL). SKIP-with-reason over silent pass.
      if ! epoch="$(to_epoch "$dt")"; then
        record "C1 expired-rules" "SKIP" "unparseable date '$dt' at ${f#"$REPO"/}:$lineno"
        continue
      fi
      age=$(( (NOW - epoch) / 86400 ))
      if [ "$age" -gt 90 ]; then
        fails=$((fails + 1))
        add_cand "C1" "$f" "$lineno" "expired ${age}d: $content"
      else
        warns=$((warns + 1))
        add_cand "C1" "$f" "$lineno" "dated ${age}d: $content"
      fi
    done < <(grep -nE "$kw" "$f" 2>/dev/null)
  done
  if [ "$fails" -gt 0 ]; then
    record "C1 expired-rules" "FAIL" "$fails rule(s) past their 90-day deadline"
  elif [ "$warns" -gt 0 ]; then
    record "C1 expired-rules" "WARN" "$warns dated rule(s) within 90d — review"
  else
    record "C1 expired-rules" "PASS" "no dated delete/remove rules"
  fi
}

# ── C2 — double bookkeeping (promoted, but prose kept) ──────────────────────
check_c2() {
  if [ "${#SETTINGS_FILES[@]}" -eq 0 ]; then
    record "C2 double-bookkeeping" "SKIP" "no settings.json in: ${SETTINGS_SEARCHED[*]#"$REPO"/}"
    return
  fi
  if [ "${#MD_FILES[@]}" -eq 0 ]; then
    record "C2 double-bookkeeping" "SKIP" "no CLAUDE.md or .claude/*.md to scan"
    return
  fi
  # Script basenames named in the settings files (hook targets, commands).
  local names s
  names="$(
    for s in "${SETTINGS_FILES[@]}"; do
      grep -oE '[A-Za-z0-9_.-]+\.sh' "$s" 2>/dev/null
    done | sort -u
  )"
  if [ -z "$names" ]; then
    record "C2 double-bookkeeping" "PASS" "settings wire no *.sh scripts"
    return
  fi
  local hits=0 name f line lineno content pl
  for f in "${MD_FILES[@]}"; do
    # One prose pass per file (fences/tables/trees excluded up front), then
    # every wired name is matched against that stream — not the raw file.
    pl="$(prose_lines "$f")"
    [ -n "$pl" ] || continue
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      while IFS= read -r line; do
        [ -n "$line" ] || continue
        lineno="${line%%:*}"
        content="${line#*:}"
        hits=$((hits + 1))
        add_cand "C2" "$f" "$lineno" "prose names wired '$name': $content"
      done < <(grep -F "$name" <<< "$pl" 2>/dev/null)
    done <<< "$names"
  done
  if [ "$hits" -gt 0 ]; then
    record "C2 double-bookkeeping" "WARN" "$hits prose mention(s) of already-wired scripts"
  else
    record "C2 double-bookkeeping" "PASS" "no prose duplicates a wired script"
  fi
}

# ── C3 — REVIEW.md presence ─────────────────────────────────────────────────
check_c3() {
  if [ ! -d "$REPO/.github" ]; then
    record "C3 review-md" "SKIP" "no .github/ (no PR flow to review against)"
  elif [ -f "$REPO/REVIEW.md" ]; then
    record "C3 review-md" "PASS" "REVIEW.md present"
  else
    record "C3 review-md" "WARN" "no REVIEW.md — Phase D can generate one"
  fi
}

# ── C4 — deterministic-rule candidates ──────────────────────────────────────
check_c4() {
  if [ "${#MD_FILES[@]}" -eq 0 ]; then
    record "C4 rule-candidates" "SKIP" "no CLAUDE.md or .claude/*.md to scan"
    return
  fi
  local kw='must|never|always|goes through|only|必ず|禁止|経由|のみ'
  local hits=0 f line lineno content
  for f in "${MD_FILES[@]}"; do
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      lineno="${line%%:*}"
      content="${line#*:}"
      hits=$((hits + 1))
      add_cand "C4" "$f" "$lineno" "$content"
    done < <(prose_lines "$f" | grep -iE "$kw" 2>/dev/null)
  done
  if [ "$hits" -gt 0 ]; then
    record "C4 rule-candidates" "WARN" "$hits imperative line(s) — skill judges which are enforceable"
  else
    record "C4 rule-candidates" "PASS" "no imperative prose found"
  fi
}

# ── C5 — gate / CI parity ───────────────────────────────────────────────────
check_c5() {
  local wfdir="$REPO/.github/workflows"
  if [ ! -d "$wfdir" ]; then
    record "C5 gate-ci-parity" "SKIP" "no .github/workflows (no CI to compare)"
    return
  fi
  if [ ! -f "$REPO/CLAUDE.md" ]; then
    record "C5 gate-ci-parity" "SKIP" "no root CLAUDE.md to read fenced commands"
    return
  fi
  # Concatenate every workflow file once as the CI haystack.
  local wfblob
  wfblob="$(find "$wfdir" -type f \( -name '*.yml' -o -name '*.yaml' \) -exec cat {} + 2>/dev/null)"
  local misses=0 line tok base
  # Lines inside ``` fences that look like a gate/verify/check command.
  while IFS= read -r line; do
    printf '%s' "$line" | grep -qiE 'verify|gate|check|lint|test' || continue
    tok="$(printf '%s' "$line" | grep -oE '[A-Za-z0-9_./-]+\.(sh|py)' | head -1)"
    [ -n "$tok" ] || tok="$(printf '%s' "$line" | awk '{print $1}')"
    [ -n "$tok" ] || continue
    base="$(basename "$tok")"
    if ! printf '%s' "$wfblob" | grep -qF "$base"; then
      misses=$((misses + 1))
      add_cand "C5" "$REPO/CLAUDE.md" "0" "gate not in CI: $line"
    fi
  done < <(awk '/^```/{f=!f; next} f' "$REPO/CLAUDE.md")
  if [ "$misses" -gt 0 ]; then
    record "C5 gate-ci-parity" "WARN" "$misses documented gate command(s) absent from CI"
  else
    record "C5 gate-ci-parity" "PASS" "documented gates appear in CI"
  fi
}

# ── C6 — wired-hook health ──────────────────────────────────────────────────
check_c6() {
  if [ "${#SETTINGS_FILES[@]}" -eq 0 ]; then
    record "C6 hooks-health" "SKIP" "no settings.json in: ${SETTINGS_SEARCHED[*]#"$REPO"/}"
    return
  fi
  if ! command -v jq >/dev/null 2>&1; then
    record "C6 hooks-health" "SKIP" "jq absent — cannot extract hook commands"
    return
  fi
  local have_sc=1
  command -v shellcheck >/dev/null 2>&1 || have_sc=0

  local commands s
  commands="$(
    for s in "${SETTINGS_FILES[@]}"; do
      jq -r '[.. | .command? // empty] | .[]' "$s" 2>/dev/null
    done
  )"
  if [ -z "$commands" ]; then
    record "C6 hooks-health" "SKIP" "settings wire no hook commands"
    return
  fi

  local ok=0 failed=0 skipped=0 cmd path details="" bn matches
  while IFS= read -r cmd; do
    [ -n "$cmd" ] || continue
    # Extract the first *.sh token — hook commands carry an interpreter and
    # env vars (bash "$CLAUDE_PROJECT_DIR/.claude/hooks/x.sh"), not a bare path.
    path="$(printf '%s' "$cmd" | grep -oE '[^"'"'"' ]*\.sh' | head -1)"
    if [ -z "$path" ]; then
      skipped=$((skipped + 1))
      details+=" [skip: no .sh in command '$cmd']"
      continue
    fi
    # Expand the repo-root var; a plugin-root or other unknown var is not
    # resolvable against this repo → SKIP that entry, naming it.
    path="${path//\$\{CLAUDE_PROJECT_DIR\}/$REPO}"
    path="${path//\$CLAUDE_PROJECT_DIR/$REPO}"
    case "$path" in
      *'$'*)
        skipped=$((skipped + 1))
        details+=" [skip: unresolved var in '$path']"
        continue
        ;;
      '~'*)
        # A ~-rooted path is the post-install home location; dotfiles-style
        # repos ship the source in-repo and symlink it home at install time —
        # it is how the dogfood target wires EVERY hook, so skipping here
        # would leave the hooks that most need auditing unverified. Resolve
        # by unique basename among repo files; none or ambiguous → SKIP.
        bn="$(basename "$path")"
        matches="$(find "$REPO" \
          \( -type d \( -name worktrees -o -name .git -o -name node_modules \) -prune \) \
          -o \( -type f -name "$bn" -print \) 2>/dev/null)"
        if [ "$(printf '%s\n' "$matches" | grep -c .)" -eq 1 ]; then
          path="$matches"
        else
          skipped=$((skipped + 1))
          details+=" [skip: home path with no unique repo source: $path]"
          continue
        fi
        ;;
      /*)
        # Absolute path outside the repo tree — not verifiable against this
        # checkout. Only an in-repo absolute path is a repo-local hook.
        if [ "${path#"$REPO"/}" = "$path" ]; then
          skipped=$((skipped + 1))
          details+=" [skip: path outside repo: $path]"
          continue
        fi
        ;;
      *)
        path="$REPO/$path"   # relativise to repo root
        ;;
    esac
    if [ ! -f "$path" ]; then
      failed=$((failed + 1))
      details+=" [MISSING: ${path#"$REPO"/}]"
      continue
    fi
    if [ ! -x "$path" ]; then
      failed=$((failed + 1))
      details+=" [NOT-EXEC: ${path#"$REPO"/}]"
      continue
    fi
    if [ "$have_sc" -eq 1 ] && ! shellcheck "$path" >/dev/null 2>&1; then
      failed=$((failed + 1))
      details+=" [SHELLCHECK-FAIL: ${path#"$REPO"/}]"
      continue
    fi
    ok=$((ok + 1))
  done <<< "$commands"

  local scnote=""
  [ "$have_sc" -eq 0 ] && scnote=" (shellcheck absent — existence/exec only)"
  if [ "$failed" -gt 0 ]; then
    record "C6 hooks-health" "FAIL" "$failed broken wired hook(s):$details"
  elif [ "$ok" -gt 0 ]; then
    record "C6 hooks-health" "PASS" "$ok wired hook(s) healthy, $skipped skipped$scnote$details"
  else
    record "C6 hooks-health" "SKIP" "no repo-local hook scripts resolved$details"
  fi
}

# ── run ─────────────────────────────────────────────────────────────────────
echo "audit: repo=$REPO"
echo "── checks ──────────────────────────────"
check_c1
check_c2
check_c3
check_c4
check_c5
check_c6

fails=0
for i in "${!R_NAME[@]}"; do
  printf "  %-4s  %-22s%s\n" \
    "${R_STATUS[$i]}" "${R_NAME[$i]}" "${R_DETAIL[$i]:+ — ${R_DETAIL[$i]}}"
  [ "${R_STATUS[$i]}" = "FAIL" ] && fails=$((fails + 1))
done

echo "---CANDIDATES---"
if [ "${#CAND[@]}" -gt 0 ]; then
  for c in "${CAND[@]}"; do
    printf '%s\n' "$c"
  done
fi

[ "$fails" -eq 0 ]
