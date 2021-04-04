#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -rf   $DIR/dist/docker
mkdir -p $DIR/dist/docker

GOFLAGS='-ldflags="-s -w"'
arch=$(go env GOARCH)
version=$(awk '/const Binary/ {print $NF}' < $DIR/internal/version/binary.go | sed 's/"//g')
goversion=$(go version | awk '{print $3}')

echo "... running tests"
./test.sh


for os in linux darwin freebsd windows; do
    echo "... building v$version for $os/$arch"
    BUILD=$(mktemp -d ${TMPDIR:-/tmp}/nsq-XXXXX)
    TARGET="nsq-$version.$os-$arch.$goversion"
    GOOS=$os GOARCH=$arch CGO_ENABLED=0 \
        make DESTDIR=$BUILD PREFIX=/$TARGET BLDFLAGS="$GOFLAGS" install
    pushd $BUILD
    sudo chown -R 0:0 $TARGET
    tar czvf $TARGET.tar.gz $TARGET
    mv $TARGET.tar.gz $DIR/dist
    popd
    make clean
    sudo rm -r $BUILD
done

docker build -t nsqio/nsqadmin_to_slack:v$version .
if [[ ! $version == *"-"* ]]; then
    echo "Tagging nsqio/nsqadmin_to_slack:v$version as the latest release."
    docker tag nsqio/nsqadmin_to_slack:v$version nsqio/nsqadmin_to_slack:latest
fi

