#!/usr/bin/env bash

die() {
	tail -n 50 /docker.log
	exit 1
}

install_docker() {
	wget -O /usr/bin/docker "$1"
	chmod +x /usr/bin/docker
}

verlte() {
	[ "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

run_daemon() {
	( set -x; exec \
		docker "$daemon_flag" --debug \
		--storage-driver "$DOCKER_STORAGE_DRIVER" \
		--pidfile "/docker.pid" \
			&> /docker.log
	) &
}

cleanup_daemon() {
	trap - EXIT
	close_daemon
	[ "$DOCKER_STORAGE_DRIVER" == "btrfs" ] && cleanup_btrfs
}

close_daemon() {
	pid=$(set -x; cat /docker.pid)
	( set -x; kill "$pid" ) 
	if ! wait "$pid"; then
		echo >&2 "warning: PID $pid from $pidFile had a nonzero exit code"
	fi
}

setup_btrfs() {
	truncate -s 1G /var/lib/docker/btrfs.img
	loopdev=$(losetup -f --show /var/lib/docker/btrfs.img)
	mkfs.btrfs "$loopdev"
	mount "$loopdev" /var/lib/docker
}

cleanup_btrfs() {
	umount "$loopdev"
	losetup -d "$loopdev"
}

set -x

daemon_flag="daemon"
verlte "$DOCKER_START_VERSION" "1.7.1" && daemon_flag="-d"

install_docker https://get.docker.com/builds/Linux/x86_64/docker-"$DOCKER_START_VERSION"

[ "$DOCKER_STORAGE_DRIVER" == "btrfs" ] && setup_btrfs

trap 'cleanup_daemon' EXIT

run_daemon

bats /pre-tests.bats
[ $? -eq 0 ] || die

[ "$DOCKER_STORAGE_DRIVER" == "devicemapper" ] && docker_run_privileged="--privileged"

[ "$DOCKER_MIGRATE_METHOD" == "tool" ] && (v1.10-migrator || exit 2);
[ "$DOCKER_MIGRATE_METHOD" == "image" ] && (
	docker load -i /v1.10-migrator.tar; \
	docker run --rm -v /var/lib/docker:/var/lib/docker $docker_run_privileged v1.10-migrator || die
)

close_daemon

daemon_flag="daemon"
install_docker https://master.dockerproject.org/linux/amd64/docker-1.10.0-dev

run_daemon
bats /post-tests.bats
[ $? -eq 0 ] || die
