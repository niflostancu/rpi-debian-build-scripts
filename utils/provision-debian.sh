#!/bin/bash
# Debian-based build host/container provisioning script.
set -e

export DEBIAN_FRONTEND=noninteractive

# install required packages
apt-get update
# build tools
apt-get -y install git curl build-essential rsync debootstrap fakeroot \
    crossbuild-essential-arm64 binfmt-support qemu-user-static \
    device-tree-compiler devscripts
# linux kernel build dependencies
apt-get -y install bc bison flex libssl-dev libncurses5-dev xz-utils cpio \
    debhelper-compat dh-exec dh-python quilt kmod libelf-dev libssl-dev
