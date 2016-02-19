#!/usr/bin/env bats

@test "validate busybox:1.24.1" {
	run docker inspect -f {{.Id}} busybox:1.24.1
	[ "$status" -eq 0 ]
	echo "id: $output"
	[ "$output" = "sha256:3240943c9ea3f72db51bea0a2428e83f3c5fa1312e19af017d026f9bcf70f84b" ]
}

@test "validate busybox:1.21.0-ubuntu" {
	run docker inspect -f {{.Id}} busybox:1.21.0-ubuntu
	[ "$status" -eq 0 ]
	echo "id: $output"
	[ "$output" = "sha256:d34ea343a882c1f8ad2692872d0a3db95cccd0d3fbdfeee015113871b4f171b9" ]
}

@test "remove busybox:1.24.1" {
	run docker rmi busybox:1.24.1
	[ "$status" -eq 0 ]
	run docker inspect -f {{.Id}} busybox:1.24.1
	[ "$status" -ne 0 ]
}

@test "repull busybox:1.24.1" {
	run docker pull busybox:1.24.1
	[ "$status" -eq 0 ]
	run docker inspect -f {{.Id}} busybox:1.24.1
	echo "id: $output"
	[ "$status" -eq 0 ]
	[ "$output" = "sha256:3240943c9ea3f72db51bea0a2428e83f3c5fa1312e19af017d026f9bcf70f84b" ]
}

@test "validate redis:2.8.23" {
	run docker inspect -f {{.Id}} redis:2.8.23
	echo "id: $output"
	[ "$status" -eq 0 ]
	[ "$output" = "sha256:a9bc1f4d38234619ecf82740b799785e306977bb2024f90e6f368cd35e103086" ]
}

@test "validate redis:2.8.23 layers" {
	output=$(docker history redis:2.8.23 | awk '{print $(NF-1)}' | tr '\n' ' ')
	echo "id: -$output-"
	[ "$output" = "SIZE 0 0 0 109 0 0 0 8.741 0 0 0 2.699 125.8 14.04 330.4 0 125.1 " ]
}

@test "validate built foobar:latest" {
	output=$(docker run --rm foobar:latest ls -l /baz | awk '{print $1" "$3" "$4" "$5" "$9}')
	[ "$output" = "-rw-r--r-- root root 4 /baz" ]
	output=$(docker run --rm foobar:latest ls -l /bax | awk '{print $1" "$3" "$4" "$5" "$9}')
	[ "$output" = "-rw-r--r-- root root 0 /bax" ]
	output=$(docker run --rm foobar:latest sh -c "[ ! -f aufs.go ] && echo missing")
	[ "$output" = "missing" ]
}
