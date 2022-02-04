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
readonly VERSION_PLACEHOLDER="{{version}}"

# Import dependencies
# shellcheck source=scripts/shared/utilities.sh
source "$SCRIPTS_DIRECTORY/shared/utilities.sh"

print_name() {
  echo "-------------------------------------------------------"
  echo "-------------------------------------------------------"
  echo "------------------- bump-everywhere -------------------"
  echo "-------------------------------------------------------"
  echo "-------------------------------------------------------"
}

clone () {
  local -r repository="$1" git_token="$2"
  echo "Cloning $repository"
  local temp_directory
  if ! temp_directory=$(mktemp -d) \
    || utilities::is_empty_or_null "$temp_directory"; then
    echo "Could not create a temporary directory"
    exit 1;
  fi
  git clone "https://x-access-token:$git_token@github.com/$repository.git" "$temp_directory" \
    || { echo "git clone failed for $repository"; exit 1; }
  cd "$temp_directory" \
    || { echo "Could not locate folder $temp_directory"; exit 1; }
  local latest_commit_sha
  if ! latest_commit_sha=$(git log -1 --format="%H") \
     || utilities::is_empty_or_null "$latest_commit_sha"; then
    echo "Could not retrieve latest commit sha"
    exit 1
  fi
  echo "Latest commit sha: $latest_commit_sha"
}

is_rerun() {
  local -r commit_message="$2"
  echo "Checking if this run is a re-run"
  local last_commit_message
  if ! last_commit_message=$(git log -1 --pretty=%B); then
    echo "Could not retrieve latest commit message"
    exit 1
  fi
  local -r expected_pattern="^${commit_message/$VERSION_PLACEHOLDER/"[0-9]+.[0-9]+.[0-9]+"}$"
  if [[ $last_commit_message =~ $expected_pattern ]]; then
    return 0
  else
    return 1
  fi
}

configure_credentials() {
  local -r repository="$1" git_token="$2" git_user="$3"
  echo "Setting up credentials"
  bash "$SCRIPTS_DIRECTORY/configure-github-repo.sh" \
          --user "$git_user" \
          --repository "$repository" \
          --token "$git_token" \
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
  local -r repository="$1"
  local logs
  if ! logs=$(bash "$SCRIPTS_DIRECTORY/print-changelog.sh" --repository "$repository") \
    || utilities::is_empty_or_null "$logs"; then
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
  echo "Updating npm version"
  bash "$SCRIPTS_DIRECTORY/bump-npm-version.sh" \
    || { echo "Could not bump npm version"; exit 1; }
  git add . \
    || { echo "git add failed"; exit 1; }
}

has_uncommited_changes() {
  local status
  if ! status=$(git status -s); then
    echo "git status has failed";
    exit 1;
  fi
  if utilities::is_empty_or_null "$status"; then return 0; else return 1; fi
}

commit_and_push() {
  local -r latest_version_tag="$1" commit_message="$2"
  if has_uncommited_changes; then
    echo "No uncommited changes"
  else
    echo "Committing & pushing"
    local -r printable_commit_message=${commit_message/$VERSION_PLACEHOLDER/$latest_version_tag}
    git commit -m "$printable_commit_message" \
      || { echo "Could not commit wit the message: $printable_commit_message"; exit 1; }
    git push -u origin master \
      || { echo "Could not git push changes"; exit 1; }
  fi
}

create_release() {
  local -r repository="$1" release_token="$2" release_type="$3"
  bash "$SCRIPTS_DIRECTORY/create-github-release.sh" \
      --repository "$repository" \
      --token "$release_token" \
      --type "$release_type" \
      || { echo "Could not create release"; exit 1; }
}

validate_parameters() {
  local -r repository="$1" git_user="$2" git_token="$3" release_type="$4" release_token="$5" commit_message="$6"
  if utilities::is_empty_or_null "$repository"; then echo "Repository name is not set."; exit 1; fi;
  if utilities::is_empty_or_null "$git_user"; then echo "Git user is not set."; exit 1; fi;
  if utilities::is_empty_or_null "$git_token"; then echo "Git access token is not set."; exit 1; fi;
  if utilities::is_empty_or_null "$release_type"; then echo "Release type is not set."; exit 1; fi;
  if utilities::is_empty_or_null "$release_token"; then echo "Release access token is not set."; exit 1; fi;
  if utilities::is_empty_or_null "$commit_message"; then echo "Commit message is not set."; exit 1; fi;
}

main() {
  local -r repository="$1" git_user="$2" git_token="$3" release_type="$4" release_token="$5" commit_message="$6"
  validate_parameters "$repository" "$git_user" "$git_token" "$release_type" "$release_token" "$commit_message"
  print_name
  clone "$repository" "$git_token"
  if is_rerun "$commit_message"; then 
    echo "It's a re-run of the script, versioning will be skipped";
  else
    configure_credentials "$repository" "$git_token" "$git_user"
    bump_and_tag
    update_readme
    create_changelog "$repository"
    local version_tag
    if ! version_tag="$(utilities::print_latest_version)"; then
      echo "Could not retrieve latest version. $version_tag"
      exit 1
    fi
    update_npm
    commit_and_push "$version_tag" "$commit_message"
  fi
  create_release "$repository" "$release_token" "$release_type"
}

# Parse parameters
while [[ "$#" -gt 0 ]]; do case $1 in
  --repository) REPOSITORY="$2"; shift;;
  --user) GIT_USER="$2"; shift;;
  --git-token) GIT_TOKEN="$2"; shift;;
  --release-type) RELEASE_TYPE="$2"; shift;;
  --release-token) RELEASE_TOKEN="$2"; shift;;
  --commit-message) COMMIT_MESSAGE="$2"; shift;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

main "$REPOSITORY" "$GIT_USER" "$GIT_TOKEN" "$RELEASE_TYPE" "$RELEASE_TOKEN" "$COMMIT_MESSAGE"
