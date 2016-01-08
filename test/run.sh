#!/usr/bin/env bash

if [ $# -lt 2 ]; then
	cat <<EOT
Usage: $0 <initial-docker-version> <storage-driver> <migrate-method>
EOT
	exit 1
fi

cd $(dirname "$0")
set -x
docker build -t docker-v1.10-migrator:test .

[ "$3" == "image" ] && MOUNT_DOCKER_IMAGE="-v $(pwd)/docker-v1.10-migrator.tar:/docker-v1.10-migrator.tar"

docker run --rm -it --privileged -e DOCKER_START_VERSION=$1 -e DOCKER_STORAGE_DRIVER=$2 -e DOCKER_MIGRATE_METHOD=$3 $MOUNT_DOCKER_IMAGE docker-v1.10-migrator:test