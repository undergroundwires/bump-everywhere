#!/usr/bin/env bash

# Increases NPM version to match the tag
# Example usage:
#   bash "bump-npm-version.sh"
# Prerequisites:
#   - Ensure your current folder is the repository root
# Dependencies:
#   - External: git
#   - Local: ./shared/utilities.sh

# Globals
readonly SCRIPTS_DIRECTORY=$(dirname "$0")

# Import dependencies
# shellcheck source=shared/utilities.sh
source "$SCRIPTS_DIRECTORY/shared/utilities.sh"

match_and_replace_version() {
  local -r content="$1" new_version="$2"
  echo "$content" | jq --arg new "$new_version" '.version = $new'
}

bump_npm_package_version() {
   local -r new_version="$1" file_name="$2"
   local original_content
   if ! original_content=$(cat "$file_name"); then
    echo "Could read \"$file_name\""
    exit 1
   fi
   local updated_content
   if ! updated_content="$(match_and_replace_version "$original_content" "$new_version")"; then
    echo "Could not match and replace"
    exit 1
   fi
   echo -e "${updated_content}" > "$file_name" \
      || { echo "Could not update file: $file_name"; exit 1; }
}

main() {
  local new_version
  if ! new_version=$(utilities::print_latest_version); then
      echo "Could not retrieve the new version. $new_version"
      exit 1;
  fi
  local -r -a file_names=('package.json' 'package-lock.json')
  for file_name in "${file_names[@]}"
  do
    if ! utilities::file_exists "$file_name"; then
      echo "Skipping.. No $file_name file exists."
      continue
    fi
    bump_npm_package_version "$new_version" "$file_name"
    echo "Updated npm version in \"$file_name\" to \"$new_version\""
  done
}

main
