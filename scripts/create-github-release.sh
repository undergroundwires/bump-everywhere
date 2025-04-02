#!/usr/bin/env bash

# Creates the release with the latest tag if any release does not already exists
# Example usage:
#   bash "create-github-release.sh" \
#    --repository "undergroundwires/privacy.sexy" \
#    --type "draft" \
#    --token "YOUR_SECRET_PAT"
# Prerequisites:
#   - Ensure your current folder is the repository root & git is installed
#   - Ensure all tags are fetched
# Dependencies:
#   - External: git, curl, jq
#   - Local: ./shared/log-commits.sh, ./shared/utilities.sh

# Globals
SELF_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
readonly SELF_DIRECTORY
readonly LOG_COMMITS_SCRIPT_PATH="$SELF_DIRECTORY/shared/log-commits.sh"

# Import dependencies
# shellcheck source=shared/utilities.sh
source "$SELF_DIRECTORY/shared/utilities.sh"

release_exists() {
    local -r version="$1" repository="$2" access_token="$3"
    local -r api_url="https://api.github.com/repos/$repository/releases/tags/$version"
    local -i status_code;
    if ! status_code=$(curl \
        --write-out '%{http_code}' \
        --silent \
        --output /dev/null \
        --header "Authorization: token $access_token" \
        "$api_url"); then
        echo "Request to check if release exists has failed"
        exit 1;
    fi
    echo "$status_code from $api_url"
    if [[ "$status_code" -eq 200 ]] ; then
        echo "Skipping creating a release as a release already exists for \"$version\""
        return 0
    elif [[ "$status_code" -eq 401 ]] ; then
        echo "401 Unauthorized: Is release access token valid?"
        return 0
    elif [[ "$status_code" -eq 404 ]] ; then
        echo "404 Not Found: \"$version\" is not yet released"
        return 1
    else
        echo "Unexpected status code: $status_code"
        exit 1;
    fi
}

print_release_notes() {
    local -r version="$1" repository="$2"
    if utilities::has_single_version; then
        echo "Initial release"
        return 0
    fi
    local version_before
    if ! version_before=$(utilities::print_previous_version); then
        echo "Could not get the previous version. $version_before"
        exit 1
    fi
    local changes
    if ! changes=$(bash "$LOG_COMMITS_SCRIPT_PATH" \
            --repository "$repository" \
            --current "$version" \
            --previous "$version_before"); then
        echo "$LOG_COMMITS_SCRIPT_PATH has failed"
        exit 1;
    fi
    if ! utilities::is_empty_or_null "$changes"; then
        printf "%s\n\n" "$changes"
    fi
    printf "[compare](https://github.com/%s/compare/%s...%s)" \
        "$repository" "$version_before" "$version"
}

create_release() {
    local -r version="$1" repository="$2" access_token="$3" release_type="$4"
    echo "Creating a new release for $version"
    local changelog
    if ! changelog=$(print_release_notes "$version" "$repository"); then
        echo "print_release_notes has failed"
        exit 1;
    fi
    local json_payload # https://developer.github.com/v3/repos/releases/#create-a-release
    if ! json_payload=$(jq -n \
            --arg version       "$version" \
            --arg body          "$changelog" \
            '{ tag_name: $version, name: $version, body: $body }'); then
        echo "jq has failed"
        exit 1;
    fi
    if is_release_type_draft "$release_type"; then
        json_payload=$(echo "$json_payload" | jq --argjson value true '. + {draft: $value}')
    fi
    if is_release_type_prerelease "$release_type"; then
        json_payload=$(echo "$json_payload" | jq --argjson value true '. + {prerelease: $value}')
    fi
    curl --header "Authorization: token $access_token" \
        "https://api.github.com/repos/$repository/releases" \
        --data "$json_payload" \
        --silent \
        --fail
}

is_release_type_draft()         { utilities::equals_case_insensitive "$1" "draft"; }
is_release_type_none()          { utilities::equals_case_insensitive "$1" "none"; }
is_release_type_prerelease()    { utilities::equals_case_insensitive "$1" "prerelease"; }
is_release_type_release()       { utilities::equals_case_insensitive "$1" "release"; }

validate_parameters() {
    local repository="$1" access_token="$2" release_type="$3"
    if utilities::is_empty_or_null "$repository"; then echo "Repository name is not set."; exit 1; fi;
    if utilities::is_empty_or_null "$release_type"; then echo "Release type is not set."; exit 1; fi;
    if ! (is_release_type_draft "$release_type" \
        || is_release_type_none "$release_type" \
        || is_release_type_prerelease "$release_type" \
        || is_release_type_release "$release_type"); then
        echo "Unkown release type: \"$release_type\".";
        exit 1;
    fi;
    if (! is_release_type_none "$release_type") \
       && utilities::is_empty_or_null "$access_token"; then
      echo "Access token is not set.";
      exit 1;
    fi;
}

main() {
    local -r repository="$1" access_token="$2" release_type="$3"
    validate_parameters "$repository" "$access_token" "$release_type"
    if is_release_type_none "$release_type"; then
        echo "Skipping release as release type is set to \"$release_type\""
        exit 0;
    fi;
    local latest_version
    if ! latest_version=$(utilities::print_latest_version); then
        echo "Could not get the latest version. $latest_version"
        exit 1;
    fi
    if ! release_exists "$latest_version" "$repository" "$access_token"; then
        create_release "$latest_version" "$repository" "$access_token" "$release_type"
    fi
}

while [[ "$#" -gt 0 ]]; do case $1 in
  --repository) REPOSITORY="$2"; shift;;
  --token) ACCESS_TOKEN="$2"; shift;;
  --type) RELEASE_TYPE="$2"; shift;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

main "$REPOSITORY" "$ACCESS_TOKEN" "$RELEASE_TYPE"
