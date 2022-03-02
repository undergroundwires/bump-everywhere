#!/usr/bin/env bash

# Get prints markdown bulletpoint list of commits
# Example usage:
#   bash "log-commits.sh" \
#    --current "0.1.1" \
#    --previous "0.1.0" \
#    --repository "undergroundwires/bump-everywhere" > list.md
# Prerequisites:
#   - Ensure your current folder is the repository root
#   - If you query with tags, ensure all tags are fetched
# Dependencies:
#   - External: git

# Globals
readonly SCRIPT_DIRECTORY=$(dirname "$0")

# Import dependencies
# shellcheck source=utilities.sh
source "$SCRIPT_DIRECTORY/utilities.sh"

# Parse parameters
while [[ "$#" -gt 0 ]]; do case $1 in
  --current) CURRENT="$2"; shift;;
  --previous) PREVIOUS="$2"; shift;;
  --repository) REPOSITORY="$2"; shift;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

# Validate parameters
if utilities::is_empty_or_null "$CURRENT"; then echo "Current tag is missing"; exit 1; fi;
if utilities::is_empty_or_null "$PREVIOUS"; then echo "Previous tag is missing"; exit 1; fi;
if utilities::is_empty_or_null "$REPOSITORY"; then echo "Repository is missing"; exit 1; fi;

escape_regex() {
  local -r text="$1"
  echo "$text" | sed -e 's/[\/&]/\\&/g'
}

validate_ref() {
  local ref="$1"
  if ! git merge-base --is-ancestor "$ref" HEAD; then
      echo "Reference does not exist in the current branch: $1"
      exit 1
  fi
}

main() {
  validate_ref "${PREVIOUS}" && validate_ref "${CURRENT}"
  local -r commit_line_start="* "
  local line_start_pattern
  if ! line_start_pattern=$(escape_regex "$commit_line_start"); then
    echo "Could not escape regex"
    exit 1
  fi
  local -r version_pattern="[0-9]\+.[0-9]\+\.[0-9]\+" # + must be escaped to get special meaning e.g. \+
  git log "${PREVIOUS}".."${CURRENT}" \
      --pretty=format:"$commit_line_start%s | [%h](https://github.com/$REPOSITORY/commit/%H)" \
      --reverse \
          | grep -v Merge \
          | sed "/^${line_start_pattern}.*${version_pattern}/d;" \
          | sed "/^${line_start_pattern}Merge PR/d;" \
          | sed "/^${line_start_pattern}Merge pull request/d;" \
          | sed "/^${line_start_pattern}Merge branch/d;"
}

main
