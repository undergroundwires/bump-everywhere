#!/usr/bin/env bash

test() {
    # arrange
    local -r git_dir="$1"
    local sut
    local -r initial_version='0.1.0'
    local -r new_version='0.2.10'
    local -r expected_package_content=$(print_package_json "$new_version")
    local -r expected_package_lock_content=$(print_package_lock_json "$new_version")
    sut=$(get_absolute_sut_path) || { echo '😢 Could not locate sut'; return 1; }
    echo "Sut: $sut"
    cd "$git_dir" || { echo "Cannot navigate to temp dir: \"$git_dir\""; return 1; }
    setup_git_env "$initial_version" "$new_version" || { echo "Could not setup the test environment"; return 1; }

    # act
    echo "Setup repository in \"$git_dir\""
    if ! bash "$sut"; then
        echo "Unexpected exit code: $?";
        return 1;
    fi

    # assert
    local -r current_dir="$(pwd)"
    echo "$current_dir"
    local -r package_content="$(cat 'package.json')"
    local -r package_lock_content="$(cat 'package-lock.json')"
    local -i status=0
    are_equal_json 'package.json' "$package_content" "$expected_package_content" || status=1
    are_equal_json 'package-lock.json' "$package_lock_content" "$expected_package_lock_content" || status=1
    return $status
}

setup_git_env() {
    local -r initial_version="$1"
    local -r new_version="$2"
    echo "Setting up git environment, initial version: \"$initial_version\", new version: \"$new_version\""
    git init -b master --quiet || { echo '😢 Could not initialize git repository'; return 1; }
    git config --local user.email "test@privacy.sexy" || { echo '😢 Could not set user e-mail'; return 1; }
    git config --local user.name "Test User" || { echo '😢 Could not set user name'; return 1; }
    print_package_json "$initial_version" > "package.json"
    print_package_lock_json "$initial_version" > "package-lock.json"
    git add . || { echo '😢 Could not add git changes'; return 1; }
    git commit -m "inital commit" --quiet || { echo '😢 Could not do initial commit'; return 1; }
    git tag "$initial_version" || { echo '😢 Could tag first version'; return 1; }
    git commit -m "next commit" --allow-empty --quiet || { echo '😢 Could not do next commit'; return 1; }
    git tag "$new_version" || { echo '😢 Could tag next version'; return 1; }
    return 0
}

main() {
    # begin
    local -r temp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'bumpeverywheretmpdir')
    echo "Test dir: \"$temp_dir\""

    # test
    test "$temp_dir"
    local -i -r test_exit_code="$?"
    echo "Test exit code: $test_exit_code"

    # cleanup
    rm -rf "$temp_dir"
    echo "Cleaned \"$temp_dir\""
    exit "$test_exit_code"
}

get_absolute_sut_path() 
{
    local -r current_dir="$(pwd)"
    local -r relative_script_dir=$(dirname "$0")
    local -r absolute_script_dir="$current_dir/$relative_script_dir"
    local -r script_dir="$absolute_script_dir/../scripts"
    local normalized
    if ! normalized=$(cd "${script_dir}" || return 1;pwd; return 0); then
        echo "Dir does not exist: ${script_dir}"
        return 1
    fi
    local -r script_path="$normalized/bump-npm-version.sh"
    echo "$script_path"
}

print_package_json() {
    local -r version="$1"
    echo "{ \"version\": \"$version\" }"
}

print_package_lock_json() {
    local -r version="$1"
    echo "{ \"version\": \"$version\", \"dependencies\": { \"ez-consent\": { \"version\": \"1.2.1\" } }  }"
}

are_equal_json() {
    local -r name="$1"
    local -r actual="$(echo "$2" | jq -cS)"
    local -r expected="$(echo "$3" | jq -cS)"
    if [ "$actual" == "$expected" ]; then
        return 0
    else
        echo "Unexpected $name. Actual: \"$actual\". Expected: \"$expected\""
        return 1
    fi
}

main