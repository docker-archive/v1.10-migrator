FROM debian:jessie
RUN apt-get update && apt-get install -y wget iptables git btrfs-tools

# install bats
RUN cd /usr/local/src/ \
    && git clone https://github.com/sstephenson/bats.git \
    && cd bats \
    && ./install.sh /usr/local

VOLUME /var/lib/docker
COPY pre-tests.bats entrypoint.sh  post-tests.bats /
COPY v1.10-migrator /usr/bin/
ENTRYPOINT /entrypoint.sh
