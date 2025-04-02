#!/usr/bin/env bash

# Globals
SELF_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
readonly SELF_DIRECTORY

# Import dependencies
# shellcheck source=test-utilities.sh
source "$SELF_DIRECTORY/test-utilities.sh"

main() {
  test_utilities::run_tests test_json_version_bump
}

test_json_version_bump() {
  # Arrange
  local -r initial_version='0.1.0'
  local -r new_version='0.2.10'
  local -r expected_package_content=$(print_package_json "$new_version")
  local -r expected_package_lock_content=$(print_package_lock_json "$new_version")
  setup_git_env "$initial_version" "$new_version" || { echo "Could not setup the test environment"; return 1; }

  # Act
  echo "Setup repository"
  if ! test_utilities::run_script 'bump-npm-version.sh'; then
    echo 'Running sut failed.'
    return 1;
  fi

  # Assert
  local -r current_dir="$(pwd)"
  echo "$current_dir"
  local -r package_content="$(cat 'package.json')"
  local -r package_lock_content="$(cat 'package-lock.json')"
  local -i status=0
  assert_equals_json 'package.json' "$package_content" "$expected_package_content" || status=1
  assert_equals_json 'package-lock.json' "$package_lock_content" "$expected_package_lock_content" || status=1
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

print_package_json() {
  local -r version="$1"
  echo "{ \"version\": \"$version\" }"
}

print_package_lock_json() {
  local -r version="$1"
  echo "{ \"version\": \"$version\", \"dependencies\": { \"ez-consent\": { \"version\": \"1.2.1\" } }  }"
}

assert_equals_json() {
  local -r name="$1"
  local -r actual="$(echo "$2" | jq -cS)"
  local -r expected="$(echo "$3" | jq -cS)"
  test_utilities::assert_equals "$expected" "$actual" "Unexpected $name."
}

main
