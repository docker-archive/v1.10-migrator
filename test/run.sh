#!/usr/bin/env bash

if [ $# -lt 2 ]; then
  cat <<EOT
Usage: $0 <initial-docker-version> <storage-driver>
EOT
  exit 1
fi

cd $(dirname "$0")
set -x
docker build -t docker-v1.10-migrator:test .

docker run --rm -it --privileged -e DOCKER_START_VERSION=$1 -e DOCKER_STORAGE_DRIVER=$2 docker-v1.10-migrator:test