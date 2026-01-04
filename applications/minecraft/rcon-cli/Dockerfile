FROM itzg/rcon-cli:1.7.3 AS rcon

FROM alpine:3.23.2

RUN apk add --no-cache bash grep
COPY --from=rcon /rcon-cli /usr/local/bin/rcon-cli

ENTRYPOINT ["/bin/sh"]
