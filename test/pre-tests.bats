#!/usr/bin/env bats

verlte() {
	[	"$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

mode="normal"
verlte $DOCKER_START_VERSION "1.8.2" && mode="legacy"


@test "pull busybox:1.24.1" {
	run docker pull busybox:1.24.1
	[ "$status" -eq 0 ]
}

@test "validate busybox:1.24.1" {
	run docker inspect -f {{.Id}} busybox:1.24.1
	echo "id: $output"
	[ "$status" -eq 0 ]
	[ "$mode" = "legacy" ] || [ "$output" = "ac6a7980c6c2fb4d29e406efb4f9784b3c67e161eb68a97ffb428d07e3e97693" ]
	[ "$mode" = "normal" ] || [ "$output" = "fc0db02f30724abc777d7ae2b2404c6d074f1e2ceca19912352aea30a42f50b7" ]
}

@test "pull busybox:1.21.0-ubuntu" {
	run docker pull busybox:1.21.0-ubuntu
	[ "$status" -eq 0 ]
}

@test "validate busybox:1.21.0-ubuntu" {
	run docker inspect -f {{.Id}} busybox:1.21.0-ubuntu
	echo "id: $output"
	[ "$status" -eq 0 ]
	[ "$mode" = "legacy" ] || [ "$output" = "607fa964666c0c08359190cb8bb6960caf678be78f45f41390e858719ce369c9" ]
	[ "$mode" = "normal" ] || [ "$output" = "a6dbc8d6ddbb9e905518a9df65f414efce038de5f253a081b1205c6cea4bac17" ]
}
