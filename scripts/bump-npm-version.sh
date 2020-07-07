#!/usr/bin/env bash

# Increases NPM version to match the tag
# Example usage:
#   bash "bump-npm-version.sh" --version "0.1.0"
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


match_and_replace_version() {
  local -r content="$1" new_version="$2"
  # shellcheck disable=SC2001
  echo "$content" \
    | sed 's/"version":[ \t]\{0,\}"[0-9]\{1,\}.[0-9]\{1,\}.[0-9]\{1,\}"/"version": "'"$new_version"'"/'
}

bump_npm_package_version() {
   local -r new_version="$1" file_name="$2"
   local original
   if ! original=$(cat "$file_name"); then
    echo "Could read \"$file_name\""
    exit 1
   fi
   local updated
   if ! updated="$(match_and_replace_version "$original" "$new_version")"; then
    echo "Could not match and replace"
    exit 1
   fi
   echo -e "${updated}" > "$file_name" \
      || { echo "Could not update file: $file_name"; exit 1; }
}

main() {
  local -r file_name="package.json"
  if ! file_exists "$file_name"; then
    echo "Skipping.. No $file_name file exists."
    exit 0;
  fi
  local new_version
  if ! new_version=$(print_latest_version); then
      echo "Could not retrieve the new version. $new_version"
      exit 1;
  fi
  bump_npm_package_version "$new_version" "$file_name"
  echo "Updated npm version to $new_version"
}

main