v1.10-migrator: build
	docker run --rm v1.10-migrator:build tar -C /go/bin -cvf - v1.10-migrator | tar -xvf -

build:
	docker build -t v1.10-migrator:build .

v1.10-migrator-local:
	godep go build -o $@ .


test: # v1.10-migrator
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
	docker save -o test/v1.10-migrator.tar v1.10-migrator:latest
endif
	$([ -f test/v1.10-migrator ] && rm test/v1.10-migrator)
	cp v1.10-migrator test/
	./test/run.sh ${DOCKER_VERSION} ${STORAGE_DRIVER} ${MIGRATE_METHOD}

docker-image: v1.10-migrator Dockerfile.image
	tar -cf - $^ | docker build -f Dockerfile.image -t v1.10-migrator -

.PHONY: build test docker-image