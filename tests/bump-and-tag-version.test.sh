#!/usr/bin/env bash

# Import dependencies
SELF_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
readonly SELF_DIRECTORY
# shellcheck source=test-utilities.sh
source "$SELF_DIRECTORY/test-utilities.sh"

main() {
  test_utilities::run_tests \
    test_increase_patch_version \
    test_sets_initial_version \
    test_tags_within_any_branch
}

test_tags_within_any_branch() {
  # Arrange
  local -r branch_name='uncommon/branch-name'
  initialize_empty_repository "$branch_name"
  git commit --message "Tagged commit" --allow-empty  || { echo '😢 Cannot do first commit'; return 1; }
  local -r expected_commit_sha_to_tag="$(git rev-parse HEAD)"

  # Act
  if ! run_sut; then
    return 1
  fi

  # Assert
  local -r tag="$(git describe --tags --abbrev=0)"
  local -r actual_commit_sha=$(git rev-parse "$tag")
  if ! test_utilities::assert_equals "$expected_commit_sha_to_tag" "$actual_commit_sha" 'Unexpected commit.'; then
    ((total_errors++))
  fi
}

test_sets_initial_version() {
  # Arrange
  local -r expected_tag='0.1.0'

  initialize_empty_repository 'master'
  git commit --message "Tagged commit" --allow-empty  || { echo '😢 Cannot do first commit'; return 1; }
  local -r expected_commit_sha_to_tag="$(git rev-parse HEAD)"

  # Act
  if ! run_sut; then
    return 1
  fi

  # Assert
  assert_expected_latest_tag "$expected_tag" "$expected_commit_sha_to_tag"
  return "$?"
}

test_increase_patch_version() {
  local -i result=0

  test_version_increase '1.5.3' '1.5.4'
  ((result+=$?))

  test_version_increase '0.0.0' '0.0.1'
  ((result+=$?))

  test_version_increase '1.22.333' '1.22.334'
  ((result+=$?))

  test_version_increase '31.31.31' '31.31.32'
  ((result+=$?))

  return "$result"
}

test_version_increase() {
  # Arrange
  local -r given="$1"
  local -r expected_tag="$2"

  initialize_empty_repository 'master'
  git commit --message "Tagged commit" --allow-empty  || { echo '😢 Cannot do first commit'; return 1; }
  git tag "$given"                                    || { echo "😢 Cannot tag $given"; return 1; }
  git commit --message "Empty commit" --allow-empty   || { echo '😢 Cannot do second commit'; return 1; }
  local -r expected_commit_sha_to_tag="$(git rev-parse HEAD)"

  # Act
  if ! run_sut; then
    return 1
  fi

  # Assert
  assert_expected_latest_tag "$expected_tag" "$expected_commit_sha_to_tag"
  return "$?"
}

initialize_empty_repository() {
  local -r branch_name="$1"
  rm -rf .git
  git init -b "$branch_name" --quiet                  || { echo '😢 Could not initialize git repository'; return 1; }
  git remote add origin "$(pwd)"                      || { echo "😢 Could not add fake origin: $(pwd)"; return 1; }
  git config --local user.email "test@privacy.sexy"   || { echo '😢 Could not set user e-mail'; return 1; }
  git config --local user.name "Test User"            || { echo '😢 Could not set user name'; return 1; }
}

run_sut() {
  test_utilities::run_script 'bump-and-tag-version.sh'
  return "$?"
}

assert_expected_latest_tag() {
  local -r expected_tag="$1"
  local -r expected_commit_sha_to_tag="$2"

  local -i total_errors=0

  local -r actual_tag="$(git describe --tags --abbrev=0)"
  if ! test_utilities::assert_equals "$expected_tag" "$actual_tag" 'Unexpected tag.'; then
    ((total_errors++))
  fi

  local -r actual_commit_sha=$(git rev-parse "$actual_tag")
  if ! test_utilities::assert_equals "$expected_commit_sha_to_tag" "$actual_commit_sha" 'Unexpected commit.'; then
    ((total_errors++))
  fi

  return "$total_errors"
}

main
