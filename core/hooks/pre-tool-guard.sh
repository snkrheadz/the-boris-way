#!/bin/bash
# PreToolUse hook: Block Bash commands that access sensitive files.
#
# Scope (be honest about what this is): an accident guard, not a security
# boundary. It catches the common mistake spellings of sensitive paths in a
# Bash command string; a determined bypass is trivial, and this list does
# NOT try to win that arms race — it is a friction device for representative
# spellings only, so resist adding ever more variants. Pair it with the
# permissions.deny block from the README (Channel B), which covers Read()
# of the same files plus **/.env — deny rules can't ship in a plugin, so
# this hook is the Channel-A layer of the same defense in depth.
#
# This runs on EVERY Bash tool call, so it stays cheap by design: one jq
# call, bash-builtin regex matches, no other subprocesses.

input=$(cat)

# Single jq pass: non-Bash tools and empty commands both yield nothing.
command=$(jq -r 'select(.tool_name == "Bash") | .tool_input.command // empty' <<<"$input" 2>/dev/null)
if [ -z "$command" ]; then
    exit 0
fi

# Public keys are not sensitive — scrub `.ssh/id_*.pub` tokens first so that
# reading a public key (cat ~/.ssh/id_ed25519.pub, ssh-copy-id -i ...) does
# not trip the `.ssh/id_` suffix below; private-key spellings still match.
shopt -s extglob
pub_pat='.ssh/id_+([A-Za-z0-9_-]).pub'
command="${command//$pub_pat/.ssh/PUBKEY}"

# One ERE: (the three spellings a command normally uses for $HOME — expanded
# absolute path, ~/, and the literal string $HOME/) × (home-relative
# sensitive paths).
home_esc=${HOME//./\\.}   # '.' is the only regex metachar realistically in $HOME
prefix_re="(\\\$HOME/|~/|${home_esc}/)"
suffix_re='(\.secrets\.env|\.aws/credentials|\.ssh/id_|\.kube/config|\.docker/config\.json|\.gnupg/|\.netrc)'
if [[ "$command" =~ $prefix_re$suffix_re ]]; then
    echo "BLOCKED: Command accesses sensitive file matching: ${BASH_REMATCH[0]}"
    echo "Use environment variables or dedicated secret managers instead."
    exit 2
fi

# Block pipe-to-shell patterns (same pattern the grep version used).
if [[ "$command" =~ (curl|wget)[[:space:]].*\|[[:space:]]*(bash|sh|zsh) ]]; then
    echo "BLOCKED: Pipe-to-shell execution detected. Download and review scripts before executing."
    exit 2
fi

exit 0
