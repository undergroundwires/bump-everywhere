#!/usr/bin/env bash

# Updates older references in README.md to newer one
# Example usage:
#   bash "bump-readme-versions.sh"
# Prerequisites:
#   - Ensure your current folder is the repository root
#   - Ensure all tags are fetched
# Dependencies:
#   - External: git
#   - Local: ./shared/utilities.sh

# Globals
readonly SCRIPTS_DIRECTORY=$(dirname "$0")

# Import dependencies
# shellcheck source=shared/utilities.sh
source "$SCRIPTS_DIRECTORY/shared/utilities.sh"

search_and_replace() {
  local -r file_name="$1" version_before="$2" new_version="$3"
  sed -e "s/${version_before}/${new_version}/g" "$file_name" > "$file_name.tmp" \
    || { echo 'Search & replace failed' ; exit 1; }
  mv "$file_name.tmp" "$file_name" \
    || { echo 'Could not update the file.' ; exit 1; }
}

file_content_contains() {
  local -r file_name="$1" text="$2"
  case $(grep -q "$text" "$file_name"; echo $?) in
  0) return 0 ;; # found
  1) return 1 ;; # not found
  *) # error
    echo "Could not check if \"$file_name\" has \"$text\""
    exit 1
    ;;
  esac
}

main() {
  if utilities::has_single_version; then
      echo "Skipping.. There were no versions before."
      return 0
  fi
  local version_before
  if ! version_before=$(utilities::print_previous_version); then
      echo "Could not get the version before. $version_before"
      exit 1;
  fi
  local -r file_name="README.md"
  if ! utilities::file_exists "$file_name"; then
    echo "Skipping.. No $file_name file exists."
    exit 0;
  fi
  if ! file_content_contains "$file_name" "$version_before"; then
    echo "Skipping.. $file_name contains no \"$version_before\" string"
    exit 0;
  fi
  local new_version
  if ! new_version=$(utilities::print_latest_version); then
      echo "Could not retrieve the new version. $new_version"
      exit 1;
  fi
  search_and_replace "$file_name" "$version_before" "$new_version"
  git add "$file_name" \
    || { echo "Git add failed for $file_name" ; exit 1; }
}

main
