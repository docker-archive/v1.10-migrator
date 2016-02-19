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
	[ "$mode" = "legacy" ] || [ "$output" = "65e4158d96256e032299e07ac28308d644c0e81d52b18dcb08847a5027b4f107" ]
	[ "$mode" = "normal" ] || [ "$output" = "fef924a0204a00b3ec67318e2ed337b189c99ea19e2bf10ed30a13b87c5e17ab" ]
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
	[ "$mode" = "legacy" ] || [ "$output" = "1fc904471127c4c91e4e97e145ec5c7a90b3b0425330f7b95683bcd4ac4f6a11" ]
	[ "$mode" = "normal" ] || [ "$output" = "1d6bbba6a3fd57eb015daaf6244787dee6aff18ece030f8b8f52a2ee0a4c19e6" ]
}

@test "validate redis:2.8.23 layers" {
	output=$(docker history redis:2.8.23 | awk '{print $(NF-1)}' | tr '\n' ' ')
	echo "id: -$output-"
	[ "$output" = "SIZE 0 0 0 109 0 0 0 8.741 0 0 0 2.699 125.8 14.04 330.4 0 125.1 " ]
}

@test "build image foobar:latest" {
	cd $(mktemp -d)
	echo "hello-world" > hello
	echo "foo" > bar
	cat <<EOT > Dockerfile
	from busybox:1.24.1
	add hello /
	run touch /bax
	run rm hello
	add bar /baz
EOT
	run docker build -t foobar:latest .
	[ "$status" -eq 0 ]
}

@test "validate built foobar:latest" {
	output=$(docker run --rm foobar:latest ls -l /baz | awk '{print $1" "$3" "$4" "$5" "$9}')
	[ "$output" = "-rw-r--r-- root root 4 /baz" ]
	output=$(docker run --rm foobar:latest ls -l /bax | awk '{print $1" "$3" "$4" "$5" "$9}')
	[ "$output" = "-rw-r--r-- root root 0 /bax" ]
	output=$(docker run --rm foobar:latest sh -c "[ ! -f aufs.go ] && echo missing")
	[ "$output" = "missing" ]
}

