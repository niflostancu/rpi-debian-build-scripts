#!/bin/bash
# Builds a bootable RaspberryPI image (with partitions)
# May be used on both files and block devices.

set -eo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/base.sh"

@import 'load_config'

# image builder options
[[ -n "$ROOTFS_DEST" ]] || sh_log_panic "No ROOTFS_DEST given!"
[[ -n "$IMAGE_DEST" ]] || sh_log_panic "No IMAGE_DEST given!"
MOUNT_TMP="${MOUNT_TMP:-/tmp/rpi.mount}"

_lo_umount() {
    if [[ "$0" != "--force" && "$DEBUG" -gt 2 ]]; then return 0; fi
    sh_log_info "Unmounting loopback device..."
    mountpoint -q "$MOUNT_TMP$RPI_FIRMWARE_DIR" && $SUDO umount "$MOUNT_TMP$RPI_FIRMWARE_DIR" || true
    mountpoint -q "$MOUNT_TMP" && $SUDO umount "$MOUNT_TMP" || true
    if [[ -n "$LO_DEV" ]]; then
        $SUDO losetup -d "$LO_DEV"
    else $SUDO losetup -D; fi
}
if [[ "$1" =~ ^(-u|--un?mount)$ ]]; then _lo_umount --force; exit 0; fi

# reseve the image file
dd if=/dev/zero of="$IMAGE_DEST" bs=1M count="$IMAGE_SIZE_MB"

_PARTED_BOOT_START=1
_PARTED_BOOT_END=$(( "$IMAGE_BOOT_PART_MB" + "$_PARTED_BOOT_START" ))
_PARTED_ROOTFS_END=$(( "$IMAGE_SIZE_MB" + "$_PARTED_BOOT_END" ))

sh_log_info "Creating partitions..."
sh_log_debug \
    '1:' "${_PARTED_BOOT_START}MiB" "${_PARTED_BOOT_END}MiB" $'\n' \
    '2:' "${_PARTED_BOOT_END}MiB" "100%"

parted --script "$IMAGE_DEST" \
    mklabel msdos \
    mkpart primary "${_PARTED_BOOT_START}MiB" "${_PARTED_BOOT_END}MiB" \
    type 1 0x0B set 1 boot on \
    mkpart primary "${_PARTED_BOOT_END}MiB" "100%" \
    type 2 0x83

LO_DEV=$($SUDO losetup -f)
$SUDO losetup -P "$LO_DEV" "$IMAGE_DEST"
sh_log_info "Loopback device $LO_DEV mapped to '$IMAGE_DEST'"
trap _lo_umount EXIT

if [[ ! -b "${LO_DEV}p1" || ! -b "${LO_DEV}p2" ]]; then
    sh_log_panic "Image partition scanning failed!"
fi

sh_log_info "Formatting partitions..."
$SUDO mkfs.vfat -n "$IMAGE_BOOT_PART_NAME" "${LO_DEV}p1"
$SUDO mkfs.ext4 -L "$IMAGE_ROOTFS_PART_NAME" "${LO_DEV}p2"

# use the /boot/firmware convention to split partitions
$SUDO mkdir -p "$MOUNT_TMP"
sh_log_debug "mount ${LO_DEV}p2 $MOUNT_TMP"
$SUDO mount "${LO_DEV}p2" "$MOUNT_TMP"
$SUDO mkdir -p "$MOUNT_TMP$RPI_FIRMWARE_DIR"
sh_log_debug "mount ${LO_DEV}p1 $MOUNT_TMP$RPI_FIRMWARE_DIR"
$SUDO mount "${LO_DEV}p1" "$MOUNT_TMP$RPI_FIRMWARE_DIR"

sh_log_info "Copying files from '$ROOTFS_DEST/' to '$MOUNT_TMP/'"
$SUDO rsync -a "$ROOTFS_DEST/" "$MOUNT_TMP/"

if [[ ! "$RPI_SKIP_BOOT_RAMDISK" =~ ^1|y(es)?$ ]]; then
    $SUDO cp -f "$ROOTFS_DEST/boot/boot.img" "$MOUNT_TMP$RPI_FIRMWARE_DIR/boot.img"
    $SUDO cp -f "$ROOTFS_DEST/boot/config-raw.txt" "$MOUNT_TMP$RPI_FIRMWARE_DIR/config.txt"
fi

# rootfs install hook
if declare -f -F "image_build_hook" >/dev/null; then
    sh_log_info "Running image_build_hook..."
    image_build_hook "$MOUNT_TMP"
fi

sh_log_debug $'RootFS files list: \n' "$(ls -lh "$MOUNT_TMP/")"
sh_log_debug $'Firmware files list: \n' "$(ls -lh "$MOUNT_TMP$RPI_FIRMWARE_DIR")"
$SUDO du -hs "$MOUNT_TMP"
$SUDO du -hs "$MOUNT_TMP$RPI_FIRMWARE_DIR"

echo "Successfully generated image!"
ls -l "$IMAGE_DEST"

