#!/bin/bash
# PreToolUse hook: Block Bash commands that access sensitive files.
#
# Scope (be honest about what this is): an accident guard, not a security
# boundary. It catches the common mistake spellings of sensitive paths in a
# Bash command string; a determined bypass is trivial. Pair it with the
# permissions.deny block from the README (Channel B), which covers Read()
# of the same files plus **/.env — deny rules can't ship in a plugin, so
# this hook is the Channel-A layer of the same defense in depth.

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null)
if [ "$tool_name" != "Bash" ]; then
    exit 0
fi

command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
if [ -z "$command" ]; then
    exit 0
fi

# Home-relative sensitive paths. Each is checked in the three spellings a
# command normally uses: expanded ($HOME already resolved by this shell),
# tilde (~/...), and the literal string $HOME/... — the latter two are how
# commands are usually written, and matching only the expanded form would
# let `cat ~/.ssh/id_rsa` sail through.
SENSITIVE_SUFFIXES=(
    ".secrets.env"
    ".aws/credentials"
    ".ssh/id_"
    ".kube/config"
    ".docker/config.json"
    ".gnupg/"
    ".netrc"
)

for suffix in "${SENSITIVE_SUFFIXES[@]}"; do
    # shellcheck disable=SC2088,SC2016  # literal "~/" and "$HOME/" are the spellings being matched, not paths to expand
    for prefix in "$HOME/" "~/" '$HOME/'; do
        if [[ "$command" == *"${prefix}${suffix}"* ]]; then
            echo "BLOCKED: Command accesses sensitive file matching: ${prefix}${suffix}"
            echo "Use environment variables or dedicated secret managers instead."
            exit 2
        fi
    done
done

# Block pipe-to-shell patterns
if echo "$command" | grep -qE '(curl|wget)\s.*\|\s*(bash|sh|zsh)'; then
    echo "BLOCKED: Pipe-to-shell execution detected. Download and review scripts before executing."
    exit 2
fi

exit 0
