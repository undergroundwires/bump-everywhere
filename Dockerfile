FROM alpine:3.12

COPY /scripts /usr/bin/scripts/

RUN apk add --no-cache bash git curl jq

ENTRYPOINT /bin/bash /usr/bin/scripts/bump-everywhere.sh \
    --repository "$0" \
    --user "$1" \
    --git-token "$2" \
    --release-type "$3" \
    --release-token "$4" \
    --commit-message "$5"