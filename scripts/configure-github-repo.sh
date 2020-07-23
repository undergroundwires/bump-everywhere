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

set_origin() {
  local -r origin_url="$1"
  git remote set-url origin "$origin_url" \
      || { echo "Failed to set remote URL to $origin_url" ; exit 1; }
}

set_user() {
  local -r user_name="$1"
  git config --local user.name "$user_name" \
      || { echo "Failed to set local user to $user_name" ; exit 1; }
  local -r user_email="$user_name@users.noreply.github.com"
  git config --local user.email "$user_email" \
      || { echo "Failed to set local user email to $user_email" ; exit 1; }
}

validate_parameters() {
  local -r repository="$1" access_token="$2" git_user="$3"
  if is_empty_or_null "$repository"; then echo "Repository name is not set."; exit 1; fi;
  if is_empty_or_null "$access_token"; then echo "Access token is not set."; exit 1; fi;
  if is_empty_or_null "$git_user"; then echo "Git user is not set."; exit 1; fi;
}

main() {
  local -r repository="$1" access_token="$2" git_user="$3"
  validate_parameters "$repository" "$access_token" "$git_user"
  set_origin "https://x-access-token:$access_token@github.com/$repository"
  set_user "$git_user"
}

# Parse parameters
while [[ "$#" -gt 0 ]]; do case $1 in
  --repository) REPOSITORY="$2"; shift;;
  --user) GIT_USER="$2"; shift;;
  --token) ACCESS_TOKEN="$2"; shift;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

main "$REPOSITORY" "$ACCESS_TOKEN" "$GIT_USER"