#!/usr/bin/env bash

has_value() {
    local -r text="$1"
    [[ -n "$text" ]]
}

is_empty_or_null()  {
    local -r text="$1"
    [[ -z "$text" ]]
}

count_tags() {
    git tag | wc -l
}

repository_has_any_tags() {
    local -i total_tags
    if ! total_tags=$(count_tags); then
        echo "Could not count tags"
        exit 1
    fi
    [[ "$total_tags" -ne 0 ]]
}

is_valid_semantic_version_string() {
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

print_latest_version() {
    if ! repository_has_any_tags; then
        exit 1;
    fi
    local -r latest_tag=$(git tag | sort -V | tail -1)
    if ! is_valid_semantic_version_string "$latest_tag"; then
        exit 1;
    fi
    echo "$latest_tag"
}

print_previous_version() {  
    local -i total_tags
    if ! total_tags=$(count_tags); then
        echo "Could not count tags"
        exit 1
    fi
    if [ "$total_tags" -le 1 ]; then
        exit 0;
    fi
    local -r previous_tag=$(git tag | sort -V | tail -1)
    if ! is_valid_semantic_version_string "$previous_tag"; then
        exit 1;
    fi
    echo "$previous_tag"
}

file_exists() { 
    local -r file=$1;
    [[ -f $file ]];
}