#!/bin/bash
# Debian-based build host provisioning script.
# Installs all build dependencies inside a Debian-like VM.
set -e

export DEBIAN_FRONTEND=noninteractive

# install required packages
apt-get update
apt-get -y install git curl build-essential fakeroot gcc-aarch64-linux-gnu \
    debootstrap binfmt-support qemu-user-static
apt-get -y build-dep linux

