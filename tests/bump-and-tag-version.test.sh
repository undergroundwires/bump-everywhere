#!/usr/bin/env bash

# Import dependencies 
readonly SELF_DIRECTORY=$(dirname "$0")
# shellcheck source=tests/test-utilities.sh
source "$SELF_DIRECTORY/test-utilities.sh"

main() {
    run_test test_increase_patch_version
}

test_increase_patch_version() {
    local -i result=0

    expect_version '1.5.3' '1.5.4'
    ((result+=$?))

    expect_version '0.0.0' '0.0.1'
    ((result+=$?))

    expect_version '1.22.333' '1.22.334'
    ((result+=$?))

    expect_version '31.31.31' '31.31.32'
    ((result+=$?))

    return "$result"
}

expect_version() {
    # Prepare
    local -r given="$1"
    local -r expected="$2"
    local actual

    rm -rf .git
    git init -b master --quiet                          || { echo '😢 Could not initialize git repository'; return 1; }
    git remote add origin "$(pwd)"                      || { echo "😢 Could not add fake origin: $(pwd)"; return 1; }
    git config --local user.email "test@privacy.sexy"   || { echo '😢 Could not set user e-mail'; return 1; }
    git config --local user.name "Test User"            || { echo '😢 Could not set user name'; return 1; }
    git commit --message "Tagged commit" --allow-empty  || { echo '😢 Cannot do first commit'; return 1; }
    git tag "$given"                                    || { echo "😢 Cannot tag $given"; return 1; }
    git commit --message "Empty commit" --allow-empty   || { echo '😢 Cannot do second commit'; return 1; }

    # Act
    local -r sut=$(get_absolute_sut_path bump-and-tag-version.sh) || { echo '😢 Could not locate sut'; return 1; }
    echo "Sut: $sut"
    bash "$sut"

    # Assert
    local -r actual="$(git describe --tags --abbrev=0)"
    if [[ "$actual" == "$expected" ]]; then
        echo -e "Success: $given returned $actual as expected."
        return 0
    else
        echo "Fail: Given $given, $expected (expected) != $actual (actual)."
        return 1
    fi
}

main
