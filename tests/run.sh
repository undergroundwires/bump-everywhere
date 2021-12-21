#!/usr/bin/env bash

readonly SELF_DIRECTORY=$(dirname "$0")


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
        # shellcheck disable=SC2001
        echo "$output" | sed 's/^/\t/' # Tab indent output
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