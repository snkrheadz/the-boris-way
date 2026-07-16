#!/usr/bin/env bash
# audit_test.sh — self-test for audit.sh.
#
# Builds two throwaway fixture repos under a temp dir and asserts that audit.sh
# DISCRIMINATES: the dirty repo fires the expected detections (and exits 1), the
# clean repo stays silent (and exits 0). A test that only proved "the script
# runs" would be worthless — each assertion below pins a specific C-check's
# red-or-green so a regression in detection is caught, not masked.
#
# No network, no dependence on the outer repo. Exit 0 iff every assertion holds.

set -uo pipefail

AUDIT="$(cd "$(dirname "$0")" && pwd)/audit.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
check() {
  # $1 = human label, $2 = "ok" | "" (nonempty-second-arg means pass)
  if [ -n "$2" ]; then
    printf '  \033[32mok\033[0m   %s\n' "$1"
    pass=$((pass + 1))
  else
    printf '  \033[31mFAIL\033[0m %s\n' "$1"
    fail=$((fail + 1))
  fi
}
contains() { case "$1" in *"$2"*) echo x ;; esac; }

# A date within the last 90 days, portably (GNU date, then BSD date).
recent_date() {
  date -d '30 days ago' +%Y-%m-%d 2>/dev/null && return 0
  date -v-30d +%Y-%m-%d 2>/dev/null && return 0
  return 1
}
RECENT="$(recent_date)"

# ── Fixture DIRTY: every violation present ──────────────────────────────────
D="$TMP/dirty"
mkdir -p "$D/.claude/hooks" "$D/.github/workflows" "$D/claude"
git -C "$D" init -q

# A dotfiles-managed global CLAUDE.md carrying its own expired rule — proves the
# claude/CLAUDE.md special-case is scanned, not just root CLAUDE.md.
cat > "$D/claude/CLAUDE.md" <<'EOF'
# Global instructions (dotfiles-managed)
- Legacy quirk from 2019-03-15; remove this note once the rewrite ships.
EOF

cat > "$D/CLAUDE.md" <<EOF
# Dirty fixture

- Workaround for the parser bug (recorded 2020-01-01; delete this rule once fixed).
- Temporary shim added $RECENT — remove when upstream lands.
- Bad date marker 2020-99-88 delete me (unparseable — must be skipped, not FAIL).
- PR creation goes through the create-pr flow only.
- You must never push to main directly.
- Secrets are validated by validate-shell.sh before commit.

| validate-shell.sh | shellcheck runner |
│   └── hooks/          # validate-shell.sh lives here
\`\`\`text
wired: validate-shell.sh
\`\`\`

\`\`\`bash
bash scripts/verify.sh   # closing gate
\`\`\`
EOF

# settings.json wires two hooks: one healthy, one missing on disk (C6 FAIL).
cat > "$D/.claude/hooks/validate-shell.sh" <<'EOF'
#!/usr/bin/env bash
echo ok
EOF
chmod +x "$D/.claude/hooks/validate-shell.sh"
cat > "$D/.claude/settings.json" <<'EOF'
{
  "hooks": {
    "PostToolUse": [
      { "hooks": [ { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/validate-shell.sh\"" } ] }
    ],
    "PreToolUse": [
      { "hooks": [ { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/gone.sh\"" } ] },
      { "hooks": [ { "type": "command", "command": "~/.claude/hooks/home-bad.sh" } ] }
    ]
  }
}
EOF
# A ~-wired hook (dotfiles style): repo ships the source at claude/hooks/,
# settings.json points at the post-install home path. The source is present
# but NOT executable, so a resolving C6 must flag it — a skipping C6 cannot.
mkdir -p "$D/claude/hooks"
cat > "$D/claude/hooks/home-bad.sh" <<'EOF'
#!/usr/bin/env bash
echo home
EOF
# (deliberately no chmod +x)

# A CI workflow that does NOT mention verify.sh → C5 parity miss.
cat > "$D/.github/workflows/main.yml" <<'EOF'
name: ci
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo build
EOF

dirty_out="$($AUDIT "$D" 2>&1)"
dirty_rc=$?

check "dirty: exits 1 (a hard invariant is broken)" "$([ "$dirty_rc" -eq 1 ] && echo x)"
check "dirty: C1 FAIL (expired 2020 rule)" \
  "$(printf '%s' "$dirty_out" | grep -E 'FAIL +C1' >/dev/null && echo x)"
check "dirty: C6 FAIL (missing wired hook)" \
  "$(printf '%s' "$dirty_out" | grep -E 'FAIL +C6' >/dev/null && echo x)"
check "dirty: unparseable date did NOT create a spurious extra C1 FAIL" \
  "$([ "$(printf '%s' "$dirty_out" | grep -cE 'FAIL +C1')" -eq 1 ] && echo x)"
check "dirty: C6 flags the missing wired hook (gone.sh MISSING)" \
  "$(printf '%s' "$dirty_out" | grep -q 'MISSING: .claude/hooks/gone.sh' && echo x)"
check "dirty: C6 does not flag the healthy hook (validate-shell.sh clean)" \
  "$(printf '%s' "$dirty_out" | grep -qE '(MISSING|NOT-EXEC|SHELLCHECK-FAIL)[^]]*validate-shell\.sh' || echo x)"
check "dirty: C6 resolves a ~-wired hook to its repo source (home-bad.sh NOT-EXEC)" \
  "$(printf '%s' "$dirty_out" | grep -q 'NOT-EXEC: claude/hooks/home-bad.sh' && echo x)"
check "dirty: claude/CLAUDE.md is scanned (expired rule there raises a C1 candidate)" \
  "$(printf '%s' "$dirty_out" | awk 'f{print} /^---CANDIDATES---$/{f=1}' | grep -E '^C1'$'\t''claude/CLAUDE.md' | grep -q 'Legacy quirk' && echo x)"

# Candidate TSV rows (below the ---CANDIDATES--- marker).
cands="$(printf '%s' "$dirty_out" | awk 'f{print} /^---CANDIDATES---$/{f=1}')"
check "dirty: C1 candidate row emitted" "$(contains "$cands" "$(printf 'C1\t')")"
check "dirty: C2 candidate row (prose names wired validate-shell.sh)" \
  "$(printf '%s' "$cands" | grep -E '^C2'$'\t' | grep -q 'validate-shell.sh' && echo x)"
check "dirty: C2 skips doc-shaped mentions (table/tree/fence) — prose row is the only one" \
  "$([ "$(printf '%s' "$cands" | grep -E '^C2'$'\t' | grep -c 'validate-shell.sh')" -eq 1 ] && echo x)"
check "dirty: C4 candidate row (imperative prose)" "$(contains "$cands" "$(printf 'C4\t')")"
check "dirty: C5 candidate row (verify.sh gate not in CI)" \
  "$(printf '%s' "$cands" | grep -E '^C5'$'\t' | grep -q 'verify.sh' && echo x)"
check "dirty: C1 recent-dated rule is WARN-tier, emitted as candidate not FAIL" \
  "$(printf '%s' "$cands" | grep -E '^C1'$'\t' | grep -q "dated" && echo x)"

# ── Fixture CLEAN: no invariant broken → exit 0 + the right SKIPs ────────────
C="$TMP/clean"
mkdir -p "$C"
git -C "$C" init -q
cat > "$C/CLAUDE.md" <<'EOF'
# Clean fixture

This repo documents its layout and commands. It carries no self-dated
teardown rules and wires no hooks, so nothing here is a promotion candidate.
EOF

clean_out="$($AUDIT "$C" 2>&1)"
clean_rc=$?

check "clean: exits 0 (no broken invariant)" "$([ "$clean_rc" -eq 0 ] && echo x)"
check "clean: C1 PASS (no dated delete rules)" \
  "$(printf '%s' "$clean_out" | grep -E 'PASS +C1' >/dev/null && echo x)"
check "clean: C2 SKIP with reason (no settings.json)" \
  "$(printf '%s' "$clean_out" | grep -E 'SKIP +C2' | grep -q 'no settings.json' && echo x)"
check "clean: C3 SKIP with reason (no .github)" \
  "$(printf '%s' "$clean_out" | grep -E 'SKIP +C3' | grep -q 'no .github' && echo x)"
check "clean: C5 SKIP with reason (no CI)" \
  "$(printf '%s' "$clean_out" | grep -E 'SKIP +C5' | grep -q 'workflows' && echo x)"
check "clean: C6 SKIP with reason (no settings.json)" \
  "$(printf '%s' "$clean_out" | grep -E 'SKIP +C6' | grep -q 'no settings.json' && echo x)"
check "clean: no candidate rows below the marker" \
  "$([ -z "$(printf '%s' "$clean_out" | awk 'f&&NF{print} /^---CANDIDATES---$/{f=1}')" ] && echo x)"

# ── verdict ─────────────────────────────────────────────────────────────────
echo
echo "audit_test: $pass passed / $fail failed"
[ "$fail" -eq 0 ]
