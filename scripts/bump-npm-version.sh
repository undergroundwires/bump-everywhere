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
readonly PACKAGES_FILE_NAME="package.json"
readonly SCRIPTS_DIRECTORY=$(dirname "$0")

# Import dependencies
# shellcheck source=scripts/shared/utilities.sh
source "$SCRIPTS_DIRECTORY/shared/utilities.sh"

# Parse parameters
while [[ "$#" -gt 0 ]]; do case $1 in
  --version) NEW_VERSION="$2"; shift;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

# Validate parameters
if is_empty_or_null "$NEW_VERSION"; then echo "New version is not set."; exit 1; fi;

match_and_replace_version() {
  local -r content="$1" new_version="$2"
  # shellcheck disable=SC2001
  echo "$content" \
    | sed 's/"version":[ \t]\{0,\}"[0-9]\{1,\}.[0-9]\{1,\}.[0-9]\{1,\}"/"version": "'"$new_version"'"/'
}

bump_npm_package_version() {
   local -r new_version="$1" file_name="$2"
   local original
   if ! original="$(cat $PACKAGES_FILE_NAME)"; then
    echo "Could read \"$PACKAGES_FILE_NAME\""
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
  bump_npm_package_version "${NEW_VERSION}" "$PACKAGES_FILE_NAME"
  echo "Updated npm version to ${NEW_VERSION}"
}

main