#!/bin/bash
# Bootstraps a base Debian rootfs for aarch64 (using qemu-static for
# cross-installation).

set -eo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
source "$SRC_DIR/lib/common.sh"
source "$SRC_DIR/config.sh"

DEB_ARCH="arm64"
DEB_VERSION="bullseye"
DEB_INSTALL_BASE_PKGS="ca-certificates,"
DEB_PROXY="http://ftp.de.debian.org/debian"
QEMU_ARCH="aarch64"

# Runs debootstrap stage 1 (bare rootfs creation)
function debootstrap_stage1() {
    local MOUNTPOINT="$1"
    local DEBOOTSTRAP_VARIANT=minbase
    local DEBOOTSTRAP_ARGS=(--foreign --arch=$DEB_ARCH --include="$DEB_INSTALL_BASE_PKGS" \
        --variant=$DEBOOTSTRAP_VARIANT $DEB_VERSION "$MOUNTPOINT" $DEB_PROXY)

    log_info "Running debootstrap stage 1..."
    log_debug debootstrap "${DEBOOTSTRAP_ARGS[@]}"
    $SUDO debootstrap "${DEBOOTSTRAP_ARGS[@]}"
}

function rootfs_copy_qemu_static() {
    local MOUNTPOINT="$1"
    local QEMU_STATIC_PATH=  # do not assign here because the error won't be returned
    if QEMU_STATIC_PATH=$(which qemu-$QEMU_ARCH-static); then
        [[ -n "$QEMU_STATIC_PATH" ]] || log_fatal "Could not find qemu-$QEMU_ARCH-static!"
        $SUDO install -D -m755 -oroot -groot --target-directory="$MOUNTPOINT/usr/bin/" "$QEMU_STATIC_PATH"
        return 0
    fi
    log_fatal "Could not find qemu-$QEMU_ARCH-static!"
}

# Runs debootstrap stage 2 (chrooted base package installation)
function debootstrap_stage2() {
    local MOUNTPOINT="$1"
    log_info "Running debootstrap stage 2..."
    "$SRC_DIR/chroot.sh" \
        /debootstrap/debootstrap --second-stage --verbose

    # echo "$DEB_SOURCES" > "$MOUNTPOINT/etc/apt/sources.list"
}

log_info "RootFS target: $ROOTFS_DEST"
if [[ -z "$1" ]]; then
    mkdir -p "$ROOTFS_DEST"
    debootstrap_stage1 "$ROOTFS_DEST"
    rootfs_copy_qemu_static "$ROOTFS_DEST"
    debootstrap_stage2 "$ROOTFS_DEST"
elif [[ "$1" == "stage2" ]]; then
    debootstrap_stage2 "$ROOTFS_DEST"
fi
