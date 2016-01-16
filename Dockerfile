FROM golang:1.5.3
RUN apt-get update && apt-get install -y build-essential
RUN git clone -b v2_02_103 https://git.fedorahosted.org/git/lvm2.git /usr/local/lvm2
RUN cd /usr/local/lvm2 \
	&& ./configure --enable-static_link \
	&& make device-mapper \
	&& make install_device-mapper

ENV GOPATH=/go:/go/src/github.com/docker/v1.10-migrator/Godeps/_workspace
COPY . /go/src/github.com/docker/v1.10-migrator
RUN go install -tags libdm_no_deferred_remove --ldflags '-extldflags "-static"' github.com/docker/v1.10-migrator
