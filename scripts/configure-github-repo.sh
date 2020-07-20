#!/usr/bin/env bash

# Sets up credentials & user to be able to push to a GitHub repository
# Example usage:
#   bash "configure-github-repo.sh" \
#     --repository "undergroundwires/bump-everywhere" \
#     --user "undergroundwires-bot" \
#     --token "SECRET-PAT-TOKEN"
# Prerequisites:
#   - Ensure your current folder is the repository root
# Dependencies:
#   - External: git
#   - Local: ./shared/utilities.sh

# Globals
readonly SCRIPTS_DIRECTORY=$(dirname "$0")

# Import dependencies
# shellcheck source=scripts/shared/utilities.sh
source "$SCRIPTS_DIRECTORY/shared/utilities.sh"

# Parse parameters
while [[ "$#" -gt 0 ]]; do case $1 in
  --repository) REPOSITORY="$2"; shift;;
  --user) GIT_USER="$2"; shift;;
  --token) ACCESS_TOKEN="$2"; shift;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

# Validate parameters
if is_empty_or_null "$REPOSITORY"; then echo "Repository name is not set."; exit 1; fi;
if is_empty_or_null "$ACCESS_TOKEN"; then echo "Access token is not set."; exit 1; fi;
if is_empty_or_null "$GIT_USER"; then echo "Git user is not set."; exit 1; fi;

set_origin() {
  local -r origin_url="$1"
  git remote set-url origin "$origin_url" \
      || { echo "Failed to set remote URL to $origin_url" ; exit 1; }
}

set_user() {
  local -r user_name="$1"
  git config --local user.name "$user_name" \
      || { echo "Failed to set local user to $user_name" ; exit 1; }
  local -r user_email="$GIT_USER@users.noreply.github.com"
  git config --local user.email "$user_email" \
      || { echo "Failed to set local user email to $user_email" ; exit 1; }
}

main() {
  set_origin "https://x-access-token:$ACCESS_TOKEN@github.com/$REPOSITORY"
  set_user "$GIT_USER"
}

main