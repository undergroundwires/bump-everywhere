#!/usr/bin/env bash

# Globals
SELF_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
readonly SELF_DIRECTORY

main() {
    local -r script_path="$SELF_DIRECTORY/middleman.sh"
    echo '[caller.sh] As GitHub actions →'
    "$script_path" "--repository undergroundwires/bump-everywhere-test" "--user undergroundwires-bot" "--git-token ***" "--release-type release" "--release-token ***" "--commit-message ⬆️ bump everywhere to {{version}}"
    echo '[caller.sh] As user →'
    "$script_path" --repository undergroundwires/bump-everywhere-test --user undergroundwires-bot --git-token "***" --release-type release --release-token "***" --commit-message "⬆️ bump everywhere to {{version}}"
}

main