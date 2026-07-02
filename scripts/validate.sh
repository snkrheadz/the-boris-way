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
#   4b. Each agents/<name>.md has frontmatter whose `name:` matches the file,
#      a description (≤10 lines — agent descriptions load into EVERY session's
#      system prompt), a `model:` pin (fail — agents have no main-session
#      exemption), and explicit `tools:` (warn — omitting inherits ALL tools).
#   4c. Every skill/agent frontmatter block PARSES as YAML (needs
#      python3+PyYAML; warns and skips otherwise). Line-greps can't catch an
#      unquoted value like `description: ... Triggers: ...` turning the block
#      into an invalid nested mapping — strict loaders then drop the file.
#   5. Every "/pack:name" cross-reference into a LOCAL pack resolves to a real
#      skill (external-marketplace refs are skipped).
#   6. shellcheck on every *.sh file, if shellcheck is available.
#   7. Every skill AND agent on disk is documented in README.md
#      (catalog-drift guard).
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

# --- frontmatter YAML parser (backs checks 4/4b — see 4c in the header) -----
have_yaml=0
if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
  have_yaml=1
else
  note "python3+PyYAML absent — skipped frontmatter YAML parse (check 4c)"
fi

frontmatter_yaml_ok() {
  # $1 = markdown file that may start with a `---` frontmatter block.
  # Exit 0 when the block parses as YAML (or there is no block — the
  # presence checks in 4/4b own that case); exit 1 when it does not parse
  # or is unterminated.
  python3 - "$1" <<'PY'
import sys, yaml
lines = open(sys.argv[1], encoding="utf-8").read().split("\n")
if not lines or lines[0] != "---":
    sys.exit(0)
try:
    end = lines[1:].index("---") + 1
except ValueError:
    sys.exit(1)
try:
    yaml.safe_load("\n".join(lines[1:end]))
except yaml.YAMLError:
    sys.exit(1)
PY
}

frontmatter() {
  # $1 = markdown file; prints the block between the first two `---` lines.
  # The single definition both check 4 and 4b parse with — fix parsing here,
  # not in per-check copies.
  awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{exit} f' "$1"
}

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
  if [ -d "$skills_dir" ]; then
    for skill_md in "$skills_dir"/*/SKILL.md; do
      [ -e "$skill_md" ] || continue
      sdir="$(basename "$(dirname "$skill_md")")"
      fm="$(frontmatter "$skill_md")"

      if [ "$have_yaml" -eq 1 ] && ! frontmatter_yaml_ok "$skill_md"; then
        err "$skill_md: frontmatter is not valid YAML (unquoted ': ' in description? quote the value)"
      fi

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
  fi

  # 4b. per-agent frontmatter — an agent's description is loaded into EVERY
  # session's system prompt, so it is checked as strictly as a skill's:
  # name matches the file, description present and lean, model pinned
  # (agents have no main-session exemption), tools explicit (omitting
  # `tools:` inherits ALL tools, over-privileging advisory agents).
  agents_dir="$dir/agents"
  if [ -d "$agents_dir" ]; then
    for agent_md in "$agents_dir"/*.md; do
      [ -e "$agent_md" ] || continue
      afile="$(basename "$agent_md" .md)"
      afm="$(frontmatter "$agent_md")"

      if [ "$have_yaml" -eq 1 ] && ! frontmatter_yaml_ok "$agent_md"; then
        err "$agent_md: frontmatter is not valid YAML (unquoted ': ' in description? quote the value)"
      fi

      aname="$(printf '%s\n' "$afm" | sed -n 's/^name:[[:space:]]*//p' | head -1)"
      if [ "$aname" != "$afile" ]; then
        err "$agent_md: frontmatter name='$aname' != file '$afile'"
      fi

      if ! printf '%s\n' "$afm" | grep -q '^description:'; then
        err "$agent_md: no description in frontmatter"
      else
        desc_lines="$(printf '%s\n' "$afm" | awk '/^description:/{d=1; n++; next} d && /^[a-z-]+:/{exit} d{n++} END{print n+0}')"
        if [ "$desc_lines" -gt 10 ]; then
          err "$agent_md: description spans $desc_lines lines — it is always-loaded context; compress to a trigger summary"
        fi
      fi

      if ! printf '%s\n' "$afm" | grep -q '^model:'; then
        err "$agent_md: no model pin (an unpinned agent inherits the main-session model)"
      fi
      if ! printf '%s\n' "$afm" | grep -q '^tools:'; then
        note "$agent_md: no tools: in frontmatter (inherits ALL tools — pin the minimal set)"
      fi
    done
    ok "pack '$pack': agents frontmatter checked"
  fi
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
    if [ -d "$d/skills" ]; then
      for s in "$d"/skills/*/; do
        [ -d "$s" ] || continue
        n="$(basename "$s")"
        if ! grep -qF "/$p:$n" "$readme" && ! grep -qF "\`$n\`" "$readme"; then
          err "skill '$p:$n' is not documented in $readme (add /$p:$n or \`$n\`)"
          readme_fail=1
        fi
      done
    fi
    if [ -d "$d/agents" ]; then
      for a in "$d"/agents/*.md; do
        [ -e "$a" ] || continue
        n="$(basename "$a" .md)"
        if ! grep -qF "\`$n\`" "$readme"; then
          err "agent '$p:$n' is not documented in $readme (add \`$n\`)"
          readme_fail=1
        fi
      done
    fi
  done < <(jq -r '.plugins[] | [.name, .source] | @tsv' "$marketplace")
  [ "$readme_fail" -eq 0 ] && ok "every skill and agent is documented in $readme"
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
