#!/bin/bash
# Builds a full Interceptor RaspberryPi image (with partitions)

set -eo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/../../lib/base.sh"

MOUNT_TMP="$1"

if [[ -z "$MOUNT_TMP" ]] ||  ! mountpoint -q "$MOUNT_TMP"; then
    sh_log_panic "Invalid RPi boot mountpoint: '$MOUNT_TMP'!"
fi

$SUDO ls -lh "$MOUNT_TMP"

