FROM golang:latest AS build

RUN mkdir -p /go/src/github.com/nsqio/nsqadmin_to_slack
COPY    .    /go/src/github.com/nsqio/nsqadmin_to_slack
WORKDIR      /go/src/github.com/nsqio/nsqadmin_to_slack

RUN export GO111MODULE=on \
 && ./test.sh \
 && CGO_ENABLED=0 go build


FROM alpine:3.13


# set up nsswitch.conf for Go's "netgo" implementation
# https://github.com/golang/go/issues/35305
RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

# Optional volumes (explicitly configure with "docker run -v ...")
# /data          - used by nsqd for persistent storage across restarts
# /etc/ssl/certs - for SSL Root CA certificates from host

COPY --from=build /go/src/github.com/nsqio/nsqadmin_to_slack/nsqadmin_to_slack /usr/local/bin/
RUN ln -s /usr/local/bin/*nsq* / \
 && ln -s /usr/local/bin/*nsq* /bin/
