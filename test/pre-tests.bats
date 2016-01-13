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


@test "pull redis:2.8.23" {
	run docker pull redis:2.8.23
	[ "$status" -eq 0 ]
}

@test "validate redis:2.8.23" {
	run docker inspect -f {{.Id}} redis:2.8.23
	echo "id: $output"
	[ "$status" -eq 0 ]
	[ "$mode" = "legacy" ] || [ "$output" = "ce0116e4e7f549950db2e8ae2a306038153b3a2ad818de9c144323a751dd7922" ]
	[ "$mode" = "normal" ] || [ "$output" = "ed9d85fcbf198b985f57287e2ce0285d3a5403ae396e1fee7d8dea325560a0ec" ]
}

@test "validate redis:2.8.23 layers" {
	output=$(docker history redis:2.8.23 | awk '{print $(NF-1)}' | tr '\n' ' ')
	echo "id: -$output-"
	[ "$output" = "SIZE 0 0 0 109 0 0 0 8.737 0 0 0 2.699 125.8 14.02 330.4 0 125.1 " ]
}

