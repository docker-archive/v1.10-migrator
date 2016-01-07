#!/usr/bin/env bats

@test "validate busybox:1.24.1" {
	run docker inspect -f {{.Id}} busybox:1.24.1
	[ "$status" -eq 0 ]
	echo "id: $output"
	[ "$output" = "sha256:d9551b4026f0e2950ddb557cc640871710bf88476ca938b71499305647231b82" ]
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
	[ "$output" = "sha256:d9551b4026f0e2950ddb557cc640871710bf88476ca938b71499305647231b82" ]
}
