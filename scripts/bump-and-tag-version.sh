#!/usr/bin/env bash

# Bumps patch number of the last version tag, tags the current commit and pushes the tag
#   - If the current commit has a tag -> Does nothing
#   - If repository has no tags, then tags clast commit with 0.1.0
# Example usage:
#    bash "bump-and-tag-version.sh"
# Prerequisites:
#   - Ensure your current folder is the repository root
#   - Ensure all tags are fetched
# Dependencies:
#   - External: git
#   - Local: ./shared/utilities.sh

# Globals
readonly SCRIPTS_DIRECTORY=$(dirname "$0")
readonly DEFAULT_VERSION="0.1.0"

# Import dependencies
# shellcheck source=scripts/shared/utilities.sh
source "$SCRIPTS_DIRECTORY/shared/utilities.sh"

tag_and_push() {
    local -r tag="$1"
    echo "Creating tag: \"$tag\""
    git tag "$tag" \
        || { echo "Could not tag: \"$tag\"" ; exit 1; }
    git push -u origin master "$tag" \
        || { echo "Could not push the tag: \"$tag\""; exit 1; }
    echo "Tag created and pushed: \"$tag\""
}

increase_patch_version() {
    local -r version="$1"
    local IFS='.'                           # Use "local" so we do not potentially break other scripts
    read -ra version_parts <<< "$version"   # Split to (-a:) array without (-r:) allowing backslashes to escape
    ((version_parts[2]++))                  # Increase patch version (after second dot; major.minor.<patch>)
    new_version="${version_parts[*]}"       # Join parts back using same IFS
    echo "$new_version"
}

is_latest_commit_tagged() {
    local latest_commit
    if ! latest_commit=$(git rev-parse HEAD) \
        || ! utilities::has_value "$latest_commit"; then
        echo "Could not read latest commit"
        exit 1
    fi
    local tag_of_latest_commit
    if ! tag_of_latest_commit=$(git tag --points-at "$latest_commit"); then
        echo "Could not check the tags of the commit $latest_commit"
        exit 1
    fi
    if ! utilities::has_value "$tag_of_latest_commit"; then
        return 1;
    fi
    if ! utilities::is_valid_semantic_version_string "$tag_of_latest_commit"; then
        echo "Latest commit tag \"$tag_of_latest_commit\" in commit \"$latest_commit\" is not a version string"
        exit 1
    fi
    return 0
}

main() {
    if ! utilities::repository_has_any_tags; then
        echo "No tag is present in the repository."
        tag_and_push "$DEFAULT_VERSION"
        exit 0
    fi
    if is_latest_commit_tagged; then
        echo "Skipping tag push. Latest commit is already tagged."
        exit 0
    fi
    local last_version
    if ! last_version=$(utilities::print_latest_version); then
        echo "Could not retrieve latest version. $last_version"
        exit 1
    fi
    local new_version
    if ! new_version=$(increase_patch_version "$last_version") \
        || utilities::is_empty_or_null "$new_version"; then
        echo "Could not increase the version"
        exit 1
    fi
    echo "Updating \"$last_version\" to \"$new_version\""
    tag_and_push "$new_version"
}

main