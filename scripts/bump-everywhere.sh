#!/usr/bin/env bash

# Bumps version, creates changelog and creates a release
# Example usage:
#   bash "scripts/bump-everywhere.sh" \
#      --repository "undergroundwires/privacy.sexy" \
#      --user "bot-commiter-name" \
#      --git-token "PAT_TOKEN" \
#      --release-token "PAT_TOKEN"
# Prerequisites:
#   - Ensure git is installed
#   - Ensure you have curl and jq installed e.g. with apk add curl jq git
# Dependencies:
#   - External: git, curl, jq
#   - Local: ./configure-github-repo.sh, ./bump-and-tag-version.sh, ./bump-readme-versions.sh,
# ./print-changelog.sh, ./bump-npm-version, ./create-github-release.sh, ./shared/utilities.sh

# Globals
readonly SCRIPTS_DIRECTORY=$(dirname "$0")
readonly VERSION_PLACEHOLDER="{version}"
readonly COMMIT_MESSAGE="⬆️ bumped to $VERSION_PLACEHOLDER"

# Import dependencies
# shellcheck source=scripts/shared/utilities.sh
source "$SCRIPTS_DIRECTORY/shared/utilities.sh"

# Parse parameters
while [[ "$#" -gt 0 ]]; do case $1 in
  --repository) REPOSITORY="$2"; shift;;
  --user) GIT_USER="$2"; shift;;
  --git-token) GIT_TOKEN="$2"; shift;;
  --release-token) RELEASE_TOKEN="$2"; shift;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

# Validate parameters
if is_empty_or_null "$REPOSITORY"; then echo "Repository name is not set."; exit 1; fi;
if is_empty_or_null "$GIT_USER"; then echo "Git user is not set."; exit 1; fi;
if is_empty_or_null "$GIT_TOKEN"; then echo "Git access token is not set."; exit 1; fi;
if is_empty_or_null "$RELEASE_TOKEN"; then echo "Release access token is not set."; exit 1; fi;

print_name() {
  echo "-------------------------------------------------------"
  echo "-------------------------------------------------------"
  echo "------------------- bump-everywhere -------------------"
  echo "-------------------------------------------------------"
  echo "-------------------------------------------------------"
}

clone () {
  echo "Cloning $REPOSITORY"
  local temp_directory
  if ! temp_directory=$(mktemp -d) \
    || is_empty_or_null "$temp_directory"; then
    echo "Could not create a temporary directory"
    exit 1;
  fi
  git clone "https://x-access-token:$GIT_TOKEN@github.com/$REPOSITORY.git" "$temp_directory" \
    || { echo "git clone failed for $REPOSITORY"; exit 1; }
  cd "$temp_directory" \
    || { echo "Could not locate folder $temp_directory"; exit 1; }
  local latest_commit_sha
  if ! latest_commit_sha=$(git log -1 --format="%H") \
     || is_empty_or_null "$latest_commit_sha"; then
    echo "Could not retrieve latest commit sha"
    exit 1
  fi
  echo "Latest commit sha: $latest_commit_sha"
}

exit_if_rerun() {
  echo "Checking if this run is a re-run"
  local last_commit_message
  if ! last_commit_message=$(git log -1 --pretty=%B); then
    echo "Could not retrieve latest commit message"
    exit 1
  fi
  local -r expected_pattern="^${COMMIT_MESSAGE/$VERSION_PLACEHOLDER/"[0-9]+.[0-9]+.[0-9]+"}$"
  if [[ $last_commit_message =~ $expected_pattern ]]; then
    echo "It's a re-run of the script. Versioning will be skipped";
    exit 0;
  else
    echo "Not a re-run"
  fi
}

configure_credentials() {
  echo "Setting up credentials"
  bash "$SCRIPTS_DIRECTORY/configure-github-repo.sh" \
          --user "undergroundwires-bot" \
          --repository "$REPOSITORY" \
          --token "$GIT_TOKEN" \
    || { echo "Could not configure credentials"; exit 1; }
}

bump_and_tag() {
  echo "Bumping and tagging version"
  bash "$SCRIPTS_DIRECTORY/bump-and-tag-version.sh" \
    || { echo "Could not bump & tag"; exit 1; }
}

update_readme() {
  echo "Updating README.md"
  bash "$SCRIPTS_DIRECTORY/bump-readme-versions.sh" \
    || { echo "Could not bump README.md"; exit 1; }
}

create_changelog() {
  local logs
  if ! logs=$(bash "$SCRIPTS_DIRECTORY/print-changelog.sh" --repository "$REPOSITORY") \
    || is_empty_or_null "$logs"; then
    printf "print-changelog.sh has failed\n%s" "$logs"
    exit 1;
  fi
  local -r file_name="CHANGELOG.md"
  echo "Creating / updating $file_name"
  echo "$logs" > "$file_name" \
    || { echo "Could not write logs to $file_name"; exit 1; } # printf removes /n's in start & end
  git add "$file_name" \
    || { echo "git add failed for $file_name"; exit 1; }
}

update_npm() {
  local -r latest_version_tag="$1"
  local -r file_name="package.json"
  if ! file_exists "$file_name"; then
    return 0
  fi
  echo "Updating npm version"
  bash "$SCRIPTS_DIRECTORY/bump-npm-version.sh" --version "$latest_version_tag" \
    || { echo "Could not bump npm version"; exit 1; }
  git add "$file_name" \
    || { echo "git add failed for $file_name"; exit 1; }
}

has_uncommited_changes() {
  local status
  if ! status=$(git status -s); then
    echo "git status has failed";
    exit 1;
  fi
  if is_empty_or_null "$status"; then return 0; else return 1; fi
}

commit_and_push() {
  local -r latest_version_tag="$1"
  if has_uncommited_changes; then
    echo "No uncommited changes"
  else
    echo "Committing & pushing"
    local -r printable_commit_message=${COMMIT_MESSAGE/$VERSION_PLACEHOLDER/$latest_version_tag}
    git commit -m "$printable_commit_message" \
      || { echo "Could not commit wit the message: $printable_commit_message"; exit 1; }
    git push -u origin master \
      || { echo "Could not push changelog"; exit 1; }
  fi
}

create_release() {
  bash "$SCRIPTS_DIRECTORY/create-github-release.sh" \
      --repository "$REPOSITORY" \
      --token "$RELEASE_TOKEN" \
      || { echo "Could not create release"; exit 1; }
}

main() {
  print_name
  clone
  exit_if_rerun
  configure_credentials
  bump_and_tag
  update_readme
  create_changelog
  local version_tag
  if ! version_tag="$(print_latest_version)" \
    || is_empty_or_null "$version_tag"; then
    echo "Could not retrieve latest version. $version_tag"
    exit 1
  fi
  update_npm "$version_tag"
  commit_and_push "$version_tag"
  create_release
}

main