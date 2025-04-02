#!/usr/bin/env bash

# Globals
SELF_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
readonly SELF_DIRECTORY

# Import dependencies
# shellcheck source=test-utilities.sh
source "$SELF_DIRECTORY/test-utilities.sh"

main() {
    local succeeded_tests=()
    local failed_tests=()
    local -i test_index=0

    # Run
    files=$(find "$SELF_DIRECTORY" -name "*.test.sh")
    for file in $files; do
        ((test_index++))
        echo "$test_index. Testing: $file"
        local output
        if output=$(bash "$file" 2>&1); then
            succeeded_tests+=("$file")
            echo $'\t'"🟢 Succeeded."
        else
            failed_tests+=("$file")
            echo $'\t'"🔴 Failed."
        fi
        echo "$output" | test_utilities::tab_indent_to_right
    done

    # Report
    echo "-----------"
    echo "Total test: $test_index"
    local -ir total_failed="${#failed_tests[@]}"
    if [ "$total_failed" -gt 0 ]; then
        echo "Failed tests ($total_failed):"
        printf '\t- %s\n' "${failed_tests[@]}"
    else
        echo "🎉 No tests are failed!"
    fi
    local -ir total_succeeded="${#succeeded_tests[@]}"
    if [ "$total_succeeded" -gt 0 ]; then
        echo "Succeeded tests ($total_succeeded):"
        printf '\t- %s\n' "${succeeded_tests[@]}"
    else
        echo "😢 No tests are succeeded!"
    fi

    exit "$total_failed"
}


main
