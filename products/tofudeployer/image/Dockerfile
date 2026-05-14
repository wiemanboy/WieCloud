FROM golang:1.25.5 AS builder
WORKDIR /app

COPY Image.yaml ./

COPY ./src/go.mod ./src/go.sum ./
RUN go mod download

COPY ./build.sh ./
COPY ./src ./src
RUN ./build.sh

FROM ghcr.io/opentofu/opentofu:1.11.5-minimal AS tofu

FROM alpine

COPY --from=tofu /usr/local/bin/tofu /usr/local/bin/tofu
COPY --from=builder /app/.build /build

ENTRYPOINT ["/build/tofudeployer"]

