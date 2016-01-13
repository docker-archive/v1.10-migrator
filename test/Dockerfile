from debian:jessie
run apt-get update && apt-get install -y wget iptables git btrfs-tools

# install bats
run cd /usr/local/src/ \
    && git clone https://github.com/sstephenson/bats.git \
    && cd bats \
    && ./install.sh /usr/local

volume /var/lib/docker
add pre-tests.bats entrypoint.sh  post-tests.bats /
add v1.10-migrator /usr/bin/
entrypoint /entrypoint.sh