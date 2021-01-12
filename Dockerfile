FROM alpine:3.12

COPY    ./scripts                   /usr/bin/scripts/
COPY    ./docker-entrypoint.sh      /usr/bin/

RUN apk add --no-cache bash git curl jq

ENTRYPOINT ["/bin/bash", "/usr/bin/docker-entrypoint.sh"]
