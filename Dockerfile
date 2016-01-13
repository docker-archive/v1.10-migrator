from golang:1.5.2
run apt-get update && apt-get install -y build-essential
run git clone -b v2_02_103 https://git.fedorahosted.org/git/lvm2.git /usr/local/lvm2
run cd /usr/local/lvm2 \
	&& ./configure --enable-static_link \
	&& make device-mapper \
	&& make install_device-mapper

env GOPATH=/go:/go/src/github.com/docker/v1.10-migrator/Godeps/_workspace
copy . /go/src/github.com/docker/v1.10-migrator
run go install -tags libdm_no_deferred_remove --ldflags '-extldflags "-static"' github.com/docker/v1.10-migrator