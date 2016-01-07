docker-v1.10-migrator: build
	docker run --rm docker-v1.10-migrator tar -C /go/bin  -cvf - docker-1.10-migrator  | tar -xvf -

build:
	docker build -t docker-v1.10-migrator .

docker-v1.10-migrator-local:
	godep go build .

.PHONY: build