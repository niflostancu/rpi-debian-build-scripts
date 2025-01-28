#!/bin/bash
# Mounts the image into a temporary location for inspection / editing

set -eo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/base.sh"

@import 'load_config'

MOUNT_TMP="${MOUNT_TMP:-/tmp/rpi.mount}"

_lo_umount() {
    if [[ "$0" != "--force" && "$DEBUG" -gt 2 ]]; then return 0; fi
    sh_log_info "Unmounting image & loopback dev..."
    mountpoint -q "$MOUNT_TMP$RPI_FIRMWARE_DIR" && \
        $SUDO umount "$MOUNT_TMP$RPI_FIRMWARE_DIR" || true
    mountpoint -q "$MOUNT_TMP" && $SUDO umount "$MOUNT_TMP" || true
    if [[ -n "$LO_DEV" ]]; then
        $SUDO losetup -d "$LO_DEV"
    else $SUDO losetup -D; fi
}
if [[ "$1" =~ ^(-u|--un?mount)$ ]]; then _lo_umount --force; exit 0; fi

# image mounter options
IMAGE_PATH="$IMAGE_DEST"
[[ -z "$1" ]] || IMAGE_PATH="$1"
[[ -f "$IMAGE_PATH" ]] || sh_log_panic "Image not found: $IMAGE_PATH"

LO_DEV=$($SUDO losetup -f)
$SUDO losetup -P "$LO_DEV" "$IMAGE_PATH"
sh_log_debug "losetup -P $LO_DEV $IMAGE_PATH"

$SUDO mkdir -p "$MOUNT_TMP"
sh_log_debug "mount ${LO_DEV}p2 $MOUNT_TMP"
$SUDO mount "${LO_DEV}p2" "$MOUNT_TMP"
$SUDO mkdir -p "$MOUNT_TMP$RPI_FIRMWARE_DIR"
sh_log_debug "mount ${LO_DEV}p1 $MOUNT_TMP$RPI_FIRMWARE_DIR"
$SUDO mount "${LO_DEV}p1" "$MOUNT_TMP$RPI_FIRMWARE_DIR"

sh_log_info "Image mapped to '$LO_DEV' + mounted to '$MOUNT_TMP'."
sh_log_info "Call '$0 --umount' to unmount it." 

