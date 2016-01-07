from debian:jessie
run apt-get update && apt-get install -y wget iptables git btrfs-tools

# install bats
run cd /usr/local/src/ \
    && git clone https://github.com/sstephenson/bats.git \
    && cd bats \
    && ./install.sh /usr/local

volume /var/lib/docker
add entrypoint.sh pre-tests.bats post-tests.bats /
entrypoint /entrypoint.sh