docker-v1.10-migrator: build
	docker run --rm docker-v1.10-migrator tar -C /go/bin  -cvf - docker-1.10-migrator  | tar -xvf -

build:
	docker build -t docker-v1.10-migrator .

docker-v1.10-migrator-local:
	godep go build .


test: # docker-v1.10-migrator
ifndef DOCKER_VERSION
	@echo "specify DOCKER_VERSION (1.9.1, 1.8.3 ...)"; exit 1;
endif
ifndef STORAGE_DRIVER
	@echo "specify STORAGE_DRIVER (overlay, aufs, devicemapper, btrfs)"; exit 1;
endif
ifndef MIGRATE_METHOD
	@echo "specify MIGRATE_METHOD (restart, tool)"; exit 1;
endif
	[ -f test/docker-1.10-migrator ] && rm test/docker-1.10-migrator
	cp docker-1.10-migrator test/
	./test/run.sh ${DOCKER_VERSION} ${STORAGE_DRIVER} ${MIGRATE_METHOD}


.PHONY: build test