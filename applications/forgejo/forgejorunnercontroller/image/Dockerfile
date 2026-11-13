FROM golang:1.26.6 AS builder
WORKDIR /app

COPY Image.yaml ./

COPY ./src/go.mod ./src/go.sum ./
RUN go mod download

COPY ./build.sh ./
COPY ./src ./src
RUN ./build.sh


FROM alpine:3.18.2

COPY --from=builder /app/.build /build

ENTRYPOINT ["/build/forgejorunnercontroller"]

