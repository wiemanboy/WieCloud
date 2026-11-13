FROM alpine:3.24.4

RUN apk update && apk add --no-cache \
    bash \
    jq \
    yq \
    git \
    curl \
    wget \
    docker-cli \
    helm \
    nodejs

ENTRYPOINT ["/bin/bash"]
