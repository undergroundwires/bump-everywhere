#!/usr/bin/env bash

# Globals
readonly ABSOLUTE_SELF_DIRECTORY=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


get_absolute_sut_path() 
{
    local -r path_from_scripts="$1"
    local -r script_dir="$ABSOLUTE_SELF_DIRECTORY/../scripts"
    local normalized
    if ! normalized=$(cd "${script_dir}" || return 1;pwd; return 0); then
        echo "Dir does not exist: ${script_dir}"
        return 1
    fi
    local -r script_path="$normalized/$path_from_scripts"
    echo "$script_path"
}

# Takes test function delegate as argument and then:
#   1. Creates a temporary directory, navigates to it
#   2. Runs the test
#   3. Cleans temporary directory, returns the test result
run_test() {
    # Beging
    local -r temp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'bumpeverywheretmpdir')
    echo "Test dir: \"$temp_dir\""
    if ! cd "$temp_dir"; then
        echo "😢 Could not navigate to $temp_dir"
        return 1
    fi

    # Test
    $1
    local -i -r test_exit_code="$?"
    echo "Test exit code: $test_exit_code"

    # Clean
    rm -rf "$temp_dir"
    echo "Cleaned \"$temp_dir\""
    exit "$test_exit_code"
}

