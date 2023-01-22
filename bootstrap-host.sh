#!/bin/bash
#
# Configure broken host machine to run correctly
#
set -ex

DGB_IMAGE=${DGB_IMAGE:-saltedlolly/digibyte}

distro=$1
shift

memtotal=$(grep ^MemTotal /proc/meminfo | awk '{print int($2/1024) }')

#
# Only do swap hack if needed
#
if [ $memtotal -lt 4096 -a $(swapon -s | wc -l) -lt 2 ]; then
    fallocate -l 4096M /swap || dd if=/dev/zero of=/swap bs=1M count=4096
    mkswap /swap
    grep -q "^/swap" /etc/fstab || echo "/swap swap swap defaults 0 0" >> /etc/fstab
    swapon -a
fi

free -m

if [ "$distro" = "trusty" -o "$distro" = "ubuntu:14.04" ]; then
    curl https://get.docker.io/gpg | apt-key add -
    echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list

    # Handle other parallel cloud init scripts that may lock the package database
    # TODO: Add timeout
    while ! apt-get update; do sleep 10; done

    while ! apt-get install -y lxc-docker; do sleep 10; done
fi

# Always clean-up, but fail successfully
docker kill digibyte-node 2>/dev/null || true
docker rm digibyte-node 2>/dev/null || true
stop docker-digibyte 2>/dev/null || true

# Always pull remote images to avoid caching issues
if [ -z "${DGB_IMAGE##*/*}" ]; then
    docker pull $DGB_IMAGE
fi

# Initialize the data container
docker volume create --name=digibyte-data
docker run -v digibyte-data:/digibyte --rm $DGB_IMAGE dgb_init

# Start digibyted via upstart and docker
curl https://raw.githubusercontent.com/saltedlolly/docker-digibyte/master/upstart.init > /etc/init/docker-digibyte.conf
start docker-digibyte

set +ex
echo "Resulting digibyte.conf:"
docker run -v digibyte-data:/digibyte --rm $DGB_IMAGE cat /digibyte/.digibyte/digibyte.conf
