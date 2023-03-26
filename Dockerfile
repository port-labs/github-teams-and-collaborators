# Use the Alpine Linux base image
FROM alpine:latest

RUN apk add --no-cache jq

ADD entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT /entrypoint.sh