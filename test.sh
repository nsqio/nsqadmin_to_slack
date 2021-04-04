#!/bin/bash
set -e

GOMAXPROCS=1 go test -timeout 90s ./...

if [ "$GOARCH" = "amd64" ] || [ "$GOARCH" = "arm64" ]; then
    # go test: -race is only supported on linux/amd64, linux/ppc64le,
    # linux/arm64, freebsd/amd64, netbsd/amd64, darwin/amd64 and windows/amd64
    GOMAXPROCS=4 go test -timeout 90s -race ./...
fi

