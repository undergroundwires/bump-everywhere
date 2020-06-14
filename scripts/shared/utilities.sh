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

print_previous_version() {  
    local -i total_tags
    if ! total_tags=$(count_tags); then
        echo "Could not count tags"
        exit 1
    fi
    if [ "$total_tags" -le 1 ]; then exit 1; fi
    git tag | sort -V | tail -2 | head -1
}

print_latest_version() {
    if ! repository_has_any_tags; then exit 1; fi
    git tag | sort -V | tail -1
}

file_exists() { 
    local -r file=$1;
    [[ -f $file ]];
}