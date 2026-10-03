FROM itzg/rcon-cli:1.7.4 AS rcon

FROM alpine:3.23.4 AS alpine

COPY --from=rcon /rcon-cli /bin/rcon-cli

ENTRYPOINT ["/bin/rcon-cli"]
