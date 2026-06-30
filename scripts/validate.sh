#!/usr/bin/env bash
# validate.sh — the marketplace's closing gate.
#
# "Done" for this repo means the catalog still installs and every skill is
# selectable. This script is the self-terminating, honest check an autonomous
# loop needs before calling work done (see CLAUDE.md §Closing gate). It only
# reads files; it never edits. Exit non-zero on any failure.
#
# Checks:
#   1. Every plugin.json and marketplace.json is valid JSON.
#   2. Each pack's plugin.json version == its marketplace.json entry version
#      (installed caches are keyed by version — a mismatch ships stale skills).
#   3. Each marketplace pack `source` directory exists and holds a plugin.json.
#   4. Each skills/<name>/SKILL.md has frontmatter whose `name:` matches its
#      directory, carries a `description:` containing "Triggers:", and pins a
#      `model:` (warn-only — an intentional main-session skill may omit it).
#   5. Every "/pack:name" cross-reference into a LOCAL pack resolves to a real
#      skill (external-marketplace refs are skipped).
#   6. shellcheck on every *.sh file, if shellcheck is available.
#   7. Every skill on disk is documented in README.md (catalog-drift guard).
#   8. `claude plugin validate .` if the CLI is available (authoritative).
#
# Usage: bash scripts/validate.sh   (run from the repo root)

set -euo pipefail

cd "$(dirname "$0")/.."

fail=0
warn=0
err()  { printf '\033[31mFAIL\033[0m %s\n' "$1" >&2; fail=$((fail + 1)); }
note() { printf '\033[33mWARN\033[0m %s\n' "$1" >&2; warn=$((warn + 1)); }
ok()   { printf '\033[32m  ok\033[0m %s\n' "$1"; }

marketplace=".claude-plugin/marketplace.json"

# --- 1. marketplace.json is valid JSON --------------------------------------
if ! jq empty "$marketplace" 2>/dev/null; then
  err "$marketplace is not valid JSON"
  echo "validate.sh aborted: catalog unreadable" >&2
  exit 1
fi
ok "$marketplace is valid JSON"

# --- iterate packs declared in the catalog ----------------------------------
# Each plugin entry: { name, source: "./pack", ... }
while IFS=$'\t' read -r pack source mp_version; do
  dir="${source#./}"
  plugin_json="$dir/.claude-plugin/plugin.json"

  # 3. source dir + plugin.json exist
  if [ ! -f "$plugin_json" ]; then
    err "pack '$pack': $plugin_json missing (source: $source)"
    continue
  fi

  # 1. plugin.json valid JSON
  if ! jq empty "$plugin_json" 2>/dev/null; then
    err "pack '$pack': $plugin_json is not valid JSON"
    continue
  fi

  # 2. version agreement
  pj_version="$(jq -r '.version' "$plugin_json")"
  if [ "$pj_version" != "$mp_version" ]; then
    err "pack '$pack': version mismatch — plugin.json=$pj_version, marketplace.json=$mp_version (bump BOTH)"
  else
    ok "pack '$pack': version $pj_version agrees"
  fi

  # 4. per-skill frontmatter
  skills_dir="$dir/skills"
  [ -d "$skills_dir" ] || continue
  for skill_md in "$skills_dir"/*/SKILL.md; do
    [ -e "$skill_md" ] || continue
    sdir="$(basename "$(dirname "$skill_md")")"
    # frontmatter is the block between the first two `---` lines
    fm="$(awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{exit} f' "$skill_md")"

    name="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1)"
    if [ "$name" != "$sdir" ]; then
      err "$skill_md: frontmatter name='$name' != directory '$sdir'"
    fi

    if ! printf '%s\n' "$fm" | grep -q '^description:'; then
      err "$skill_md: no description in frontmatter"
    elif ! printf '%s\n' "$fm" | grep -q 'Triggers:'; then
      err "$skill_md: description lacks 'Triggers:' (the auto-selection surface)"
    fi

    if ! printf '%s\n' "$fm" | grep -q '^model:'; then
      note "$skill_md: no model pin (intended main-session skill? otherwise pin one)"
    fi
  done
  ok "pack '$pack': skills frontmatter checked"
done < <(jq -r '.plugins[] | [.name, .source, .version] | @tsv' "$marketplace")

# --- 5. cross-reference integrity -------------------------------------------
# Descriptions name sibling skills as "For X use /pack:name instead" — the
# boundary that keeps auto-selection unambiguous. A reference into a LOCAL pack
# must resolve to a real skill; refs into external marketplaces (e.g.
# /claude-md-management:*) are out of our control and skipped.
local_packs="$(jq -r '.plugins[].name' "$marketplace")"
valid_refs="$(
  while IFS=$'\t' read -r p src; do
    d="${src#./}"
    [ -d "$d/skills" ] || continue
    for s in "$d"/skills/*/; do
      [ -d "$s" ] || continue
      printf '%s:%s\n' "$p" "$(basename "$s")"
    done
  done < <(jq -r '.plugins[] | [.name, .source] | @tsv' "$marketplace")
)"
xref_fail=0
while read -r ref; do
  [ -n "$ref" ] || continue
  pack="${ref%%:*}"
  printf '%s\n' "$local_packs" | grep -qx "$pack" || continue  # external pack — skip
  if ! printf '%s\n' "$valid_refs" | grep -qx "$ref"; then
    err "dangling cross-reference '/$ref' (no such skill in local pack '$pack')"
    xref_fail=1
  fi
done < <(grep -rhoE '/[a-z][a-z0-9-]*:[a-z][a-z0-9-]+' --include=SKILL.md . | sed 's#^/##' | sort -u)
[ "$xref_fail" -eq 0 ] && ok "cross-references resolve (local packs)"

# --- 6. shell static analysis (gates when shellcheck is present) -------------
# The only executable code in this repo is the gate itself and the hooks.
# Wiring shellcheck in means "validate.sh passed" implies the shell is clean,
# instead of relying on a human to remember to run it. (avoid mapfile — keep
# bash 3.2 / macOS compatibility, matching the rest of this script.)
if command -v shellcheck >/dev/null 2>&1; then
  sh_files=()
  while IFS= read -r f; do sh_files+=("$f"); done \
    < <(find . -path ./.git -prune -o -name '*.sh' -print | sort)
  if [ "${#sh_files[@]}" -eq 0 ]; then
    note "no *.sh files found to lint"
  elif shellcheck "${sh_files[@]}"; then
    ok "shellcheck clean (${#sh_files[@]} file(s))"
  else
    err "shellcheck reported problems (run 'shellcheck' on the *.sh files above)"
  fi
else
  note "shellcheck absent — skipped shell static analysis"
fi

# --- 7. README ↔ catalog drift ----------------------------------------------
# README.md advertises each pack's skills by hand. Every skill on disk must be
# documented there (as "/pack:name" or a backtick-quoted `name`) so a new skill
# can't ship invisible. README-only entries are out of scope — this guards the
# disk → docs direction, where drift hides real skills from consumers.
readme="README.md"
if [ ! -f "$readme" ]; then
  note "$readme absent — skipped README drift check"
else
  readme_fail=0
  while IFS=$'\t' read -r p src; do
    d="${src#./}"
    [ -d "$d/skills" ] || continue
    for s in "$d"/skills/*/; do
      [ -d "$s" ] || continue
      n="$(basename "$s")"
      if ! grep -qF "/$p:$n" "$readme" && ! grep -qF "\`$n\`" "$readme"; then
        err "skill '$p:$n' is not documented in $readme (add /$p:$n or \`$n\`)"
        readme_fail=1
      fi
    done
  done < <(jq -r '.plugins[] | [.name, .source] | @tsv' "$marketplace")
  [ "$readme_fail" -eq 0 ] && ok "every skill is documented in $readme"
fi

# --- 8. authoritative CLI check (optional) ----------------------------------
if command -v claude >/dev/null 2>&1; then
  if claude plugin validate . >/dev/null 2>&1; then
    ok "claude plugin validate ."
  else
    err "claude plugin validate . reported problems (run it directly to see them)"
  fi
else
  note "claude CLI absent — skipped 'claude plugin validate .'"
fi

# --- verdict ----------------------------------------------------------------
echo
if [ "$fail" -gt 0 ]; then
  printf '\033[31m%d failure(s)\033[0m, %d warning(s)\n' "$fail" "$warn" >&2
  exit 1
fi
printf '\033[32mall checks passed\033[0m (%d warning(s))\n' "$warn"
