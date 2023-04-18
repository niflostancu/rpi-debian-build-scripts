#!/bin/bash
# Debian-based build host provisioning script.
# Installs all build dependencies inside a Debian-like VM.
set -e

export DEBIAN_FRONTEND=noninteractive

# install required packages
apt-get update
# build tools
apt-get -y install git curl build-essential fakeroot crossbuild-essential-arm64 \
    debootstrap binfmt-support qemu-user-static
# linux kernel build dependencies
apt-get -y install bc bison flex libssl-dev libncurses5-dev xz-utils cpio \
    debhelper-compat dh-exec dh-python quilt
