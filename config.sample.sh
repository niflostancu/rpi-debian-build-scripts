#!/bin/bash
# Local configuration file
# Rename to 'config.sh' for scripts to load it.

# Sudo-like utility to use (when root is required)
SUDO=sudo

# destination dirs
ROOTFS_DEST="/tmp/rpi-nas/rootfs/"
KERNEL_DEST="/tmp/rpi-nas/kernel-build/"

# cross compiler options
CROSS_COMPILER="aarch64-linux-gnu-"

# kernel compile options
KERNEL_MAKE_THREADS=8
# KERNEL_DEFCONFIG=interceptor_defconfig

