#!/usr/bin/env bash

# Creates the release with the latest tag if any release does not already exists
# Example usage:
#   bash "create-github-release.sh" \
#    --repository "undergroundwires/privacy.sexy" \
#    --token "YOUR_SECRET_PAT"
# Prerequisites:
#   - Ensure your current folder is the repository root & git is installed
#   - Ensure all tags are fetched
# Dependencies:
#   - External: git, curl, jq
#   - Local: ./shared/log-commits.sh, ./shared/utilities.sh

# Globals
readonly SCRIPTS_DIRECTORY=$(dirname "$0")
readonly LOG_COMMITS_SCRIPT_PATH="$SCRIPTS_DIRECTORY/shared/log-commits.sh"

# Import dependencies
# shellcheck source=scripts/shared/utilities.sh
source "$SCRIPTS_DIRECTORY/shared/utilities.sh"

# Parse parameters
while [[ "$#" -gt 0 ]]; do case $1 in
  --repository) REPOSITORY="$2"; shift;;
  --token) ACCESS_TOKEN="$2"; shift;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

# Validate parameters
if is_empty_or_null "$REPOSITORY"; then echo "Repository name is not set."; exit 1; fi;
if is_empty_or_null "$ACCESS_TOKEN"; then echo "Access token is not set."; exit 1; fi;

release_exists() {
    local -r version="$1"
    local -r api_url="https://api.github.com/repos/$REPOSITORY/releases/tags/$version"
    local -i status_code;
    if ! status_code=$(curl \
        --write-out '%{http_code}' \
        --silent \
        --output /dev/null \
        --header "Authorization: token $ACCESS_TOKEN" \
        "$api_url"); then
        echo "Request to check if release exists has failed"
        exit 1;
    fi
    if [[ "$status_code" -eq 200 ]] ; then
        echo "Skipping creating a release as a release already exists for $version"
        return 0
    elif [[ "$status_code" -eq 404 ]] ; then
        echo "$version is not yet released"
        return 1
    else
        echo "Unknown status code: $status_code"
        exit 1;
    fi
}

has_single_version() {
    local -i total_tags
    if ! total_tags=$(count_tags); then
        echo "Could not count tags"
        exit 1
    fi
    if [ "$total_tags" -eq "1" ]; then
        return 0 # There is only a a single tag
    fi
    return 1 # There are none or multiple tags
}

print_release_notes() {
    local -r version="$1"
    if has_single_version; then 
        echo "Initial release"
        return 0
    fi
    local version_before
    if ! version_before=$(print_previous_version); then
        echo "Could not get the previous version. $version_before"
        exit 1
    fi
    local changes
    if ! changes=$(bash "$LOG_COMMITS_SCRIPT_PATH" \
            --repository "$REPOSITORY" \
            --current "$version" \
            --previous "$version_before"); then
        echo "$LOG_COMMITS_SCRIPT_PATH has failed"
        exit 1;
    fi
    if ! is_empty_or_null "$changes"; then
        printf "%s\n\n" "$changes"
    fi
    printf "[compare](https://github.com/%s/compare/%s...%s)" \
        "$REPOSITORY" "$version_before" "$version"
}

create_release() {
    local version="$1"
    echo "Creating a new release for $version"
    local changelog
    if ! changelog=$(print_release_notes "$version"); then
        echo "print_release_notes has failed"
        exit 1;
    fi
    local json_payload
    if ! json_payload=$(jq -n \
            --arg version       "$version" \
            --arg body          "$changelog" \
            '{ tag_name: $version, name: $version, body: $body }'); then
        echo "jq has failed"
        exit 1;
    fi
    curl --header "Authorization: token $ACCESS_TOKEN" \
        "https://api.github.com/repos/$REPOSITORY/releases" \
        --data "$json_payload" \
        --silent \
        --fail
}

main() {
    local latest_version
    if ! latest_version=$(print_latest_version); then
        echo "Could not get the latest version. $latest_version"
        exit 1;
    fi
    if ! release_exists "$latest_version"; then
        create_release "$latest_version"
    fi
}

main