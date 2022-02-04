#!/usr/bin/env bash

utilities::has_value() {
    local -r text="$1"
    [[ -n "$text" ]]
}

utilities::is_empty_or_null()  {
    local -r text="$1"
    [[ -z "$text" ]]
}

utilities::count_tags() {
    git tag | wc -l
}

utilities::repository_has_any_tags() {
    local -i total_tags
    if ! total_tags=$(utilities::count_tags); then
        echo "Could not count tags"
        exit 1
    fi
    [[ "$total_tags" -ne 0 ]]
}

utilities::is_valid_semantic_version_string() {
    local version="$1"
    local -i -r MAX_LENGTH=256 # for package.json compatibility: https://github.com/npm/node-semver/blob/master/internal/constants.js
    if (( ${#version} > MAX_LENGTH )); then
        echo "Version \"$version\" is too long (max: $MAX_LENGTH, but was: ${#version})"
        return 1
    fi
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        echo "Version \"$version\" is invalid (not in \`major.minor.patch\` format)"
        return 1
    fi
    return 0
}

# Prints latest version, exists with positive code if it cannot
utilities::print_latest_version() {
    if ! utilities::repository_has_any_tags; then
        exit 1;
    fi
    local -r latest_tag=$(git tag | sort -V | tail -1)
    if ! utilities::is_valid_semantic_version_string "$latest_tag"; then
        exit 1;
    fi
    echo "$latest_tag"
}

utilities::has_single_version() {
    local -i total_tags
    if ! total_tags=$(utilities::count_tags); then
        echo "Could not count tags"
        exit 1
    fi
    if [ "$total_tags" -eq "1" ]; then
        return 0 # There is only a a single tag
    fi
    return 1 # There are none or multiple tags
}

# Prints latest version, exists with positive code if it cannot
utilities::print_previous_version() {  
    local -i total_tags
    if ! total_tags=$(utilities::count_tags); then
        echo "Could not count tags"
        exit 1
    fi
    if [ "$total_tags" -le 1 ]; then
        echo "There's only a single version"
        exit 1;
    fi
    local -r previous_tag=$(git tag | sort -V | tail -2 | head -1)
    if ! utilities::is_valid_semantic_version_string "$previous_tag"; then
        exit 1;
    fi
    echo "$previous_tag"
}

utilities::file_exists() { 
    local -r file=$1;
    [[ -f $file ]];
}

utilities::equals_case_insensitive() { 
    [[ "${1,,}" = "${2,,}" ]];
}
