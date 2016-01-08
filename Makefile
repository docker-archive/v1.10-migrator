docker-v1.10-migrator: build
	docker run --rm docker-v1.10-migrator:build tar -C /go/bin -cvf - docker-v1.10-migrator | tar -xvf -

build:
	docker build -t docker-v1.10-migrator:build .

docker-v1.10-migrator-local:
	godep go build -o $@ .


test: # docker-v1.10-migrator
ifndef DOCKER_VERSION
	@echo "specify DOCKER_VERSION (1.9.1, 1.8.3 ...)"; exit 1;
endif
ifndef STORAGE_DRIVER
	@echo "specify STORAGE_DRIVER (overlay, aufs, devicemapper, btrfs)"; exit 1;
endif
ifndef MIGRATE_METHOD
	@echo "specify MIGRATE_METHOD (restart, tool, image)"; exit 1;
endif
ifeq ($(MIGRATE_METHOD),image)
	docker save -o test/docker-v1.10-migrator.tar docker-v1.10-migrator:latest
endif
	$([ -f test/docker-v1.10-migrator ] && rm test/docker-v1.10-migrator)
	cp docker-v1.10-migrator test/
	./test/run.sh ${DOCKER_VERSION} ${STORAGE_DRIVER} ${MIGRATE_METHOD}

docker-image: docker-v1.10-migrator Dockerfile.image
	tar -cf - $^ | docker build -f Dockerfile.image -t docker-v1.10-migrator -

.PHONY: build test docker-image