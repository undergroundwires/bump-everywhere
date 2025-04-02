#!/usr/bin/env bash

# Writes changelog in markdown format to std out.
# Example usage:
#   local changelog
#   if ! changelog=$(bash "print-changelog.sh" --repository "undergroundwires/privacy.sexy"); then
#     echo "Could not create changelog"
#   fi
# Prerequisites:
#   - Ensure your current folder is the repository root
#   - Ensure all tags are fetched
# Dependencies:
#   - External: git
#   - Local: ./log-commits.sh, ./shared/utilities.sh

# Globals
SELF_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
readonly SELF_DIRECTORY
readonly LOG_COMMITS_SCRIPT_PATH="$SELF_DIRECTORY/shared/log-commits.sh"

# Import dependencies
# shellcheck source=shared/utilities.sh
source "$SELF_DIRECTORY/shared/utilities.sh"

print_title() {
  local -r tag="$1"
  local tag_date
  if ! tag_date=$(git log -1 --pretty=format:'%ad' --date=short "$tag") \
    || utilities::is_empty_or_null "$tag_date"; then
    echo "Cannot get tag date for $tag"
    exit 1
  fi
  printf "\n## %s (%s)\n\n" "$tag" "$tag_date"
}

print_all_versions_from_latest() {
  git tag | sort -V -r
}

print_tags_except_first() {
  local -r repository="$1"
  local tags
  if ! tags=$(print_all_versions_from_latest); then
    echo "Could not list & sort tags"
    exit 1;
  fi
  local current_tag=0;
  for next_tag in $tags
  do
    if [ "$current_tag" != 0 ]; then
        print_title "$current_tag"
        local changes
        if ! changes=$(bash "$LOG_COMMITS_SCRIPT_PATH" \
            --repository "$repository" \
            --current "$current_tag" \
            --previous "$next_tag"); then
          echo "$LOG_COMMITS_SCRIPT_PATH has failed:"
          echo "$changes"
          exit 1
        fi
        if [[ $changes ]]; then
          printf "%s\n\n" "$changes"
        fi
        printf "[compare](https://github.com/%s/compare/%s...%s)" "$repository" "$next_tag" "$current_tag"
        printf "\n"
    fi
    current_tag=${next_tag}
  done
}

print_initial_commit_sha() {
  git rev-list --max-parents=0 HEAD
}

print_first_version() {
  git tag | sort -V | head -1
}

print_commit_sha_of_tag() {
  local -r tag="$1"
  git rev-list -n 1 "$tag" \
    || { echo "Cannot get the comit for tag $tag"; exit 1; }
}

print_first_tag() {
  local -r repository="$1"
  local first_tag
  if ! first_tag=$(print_first_version) \
    || utilities::is_empty_or_null "$first_tag"; then
    echo "Cannot get the first tag"
    exit 1
  fi
  print_title "$first_tag"
  local first_commit_with_tag_sha
  if ! first_commit_with_tag_sha=$(print_commit_sha_of_tag "$first_tag") \
    || utilities::is_empty_or_null "$first_commit_with_tag_sha"; then
    echo "Cannot get first commit with tag: $first_tag"
    exit 1
  fi
  local initial_commit_sha
  if ! initial_commit_sha=$(print_initial_commit_sha) \
    || utilities::is_empty_or_null "$initial_commit_sha"; then
    echo "Cannot get initial commit";
    exit 1;
  fi
  if [ "$first_commit_with_tag_sha" == "$initial_commit_sha" ]; then
    printf "%s | [commits](https://github.com/%s/commit/%s)" \
        "Initial release" "$repository" "$initial_commit_sha"
    return 0
  fi
  local changes
  if ! changes=$(bash "$LOG_COMMITS_SCRIPT_PATH" \
      --repository "$repository" \
      --current "$first_commit_with_tag_sha" \
      --previous "$initial_commit_sha"); then
    echo "$LOG_COMMITS_SCRIPT_PATH has failed"
    exit 1;
  fi
  if ! utilities::is_empty_or_null "$changes"; then
    printf "%s\n" "$changes"
  fi
  printf "[compare](https://github.com/%s/compare/%s...%s)" \
    "$repository" "$initial_commit_sha" "$first_commit_with_tag_sha"
}

main() {
  local -r repository="$1"
  if utilities::is_empty_or_null "$repository"; then echo "Repository name is not set."; exit 1; fi;
  printf "# Changelog\n"
  print_tags_except_first "$repository"
  print_first_tag "$repository"
  printf "\n\n"
}

while [[ "$#" -gt 0 ]]; do case $1 in
  --repository) REPOSITORY="$2"; shift;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

main "$REPOSITORY"
