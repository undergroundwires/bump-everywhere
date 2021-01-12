#!/usr/bin/env bash

while [[ "$#" -gt 0 ]]; do case $1 in
  --repository) REPOSITORY="$2"; shift;;
  --user) USER="$2"; shift;;
  --git-token) GIT_TOKEN="$2"; shift;;
  --release-type) RELEASE_TYPE="$2"; shift;;
  --release-token) RELEASE_TOKEN="$2"; shift;;
  --commit-message) COMMIT_MESAGE="$2"; shift;;
  *) echo "[script.sh] Unknown parameter passed: '$1'"; exit 1;;
esac; shift; done

echo "[script.sh] repository: $REPOSITORY, user: $USER, git-token: $GIT_TOKEN, release-type: $RELEASE_TYPE, release-token: $RELEASE_TOKEN, commit-message: $COMMIT_MESAGE"
