#!/bin/bash
# Builds a full Interceptor RaspberryPi image (with partitions)

set -eo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
source "$SRC_DIR/lib/common.sh"

MOUNT_TMP="$1"

if [[ -z "$MOUNT_TMP" ]] ||  ! mountpoint -q "$MOUNT_TMP"; then
    log_fatal "Invalid RPi boot mountpoint: '$MOUNT_TMP'!"
fi

if [[ -n "$BUILD_FULL_IMAGE" && -z "$RPI_SKIP_BOOT_RAMDISK" ]]; then
    # also copy kernel files
    $SUDO cp -f "$KERNEL_DISTRIB_DIR/"*".dtb" "$MOUNT_TMP/"
fi

$SUDO ls -lh "$MOUNT_TMP"

