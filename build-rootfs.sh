#!/bin/bash
# Bootstraps a base Debian rootfs for aarch64 (using qemu-static for
# cross-installation).

set -eo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/base.sh"

@import 'load_config'

[[ -n "$ROOTFS_DEST" ]] || sh_log_panic "No ROOTFS_DEST given!"
DEB_ARCH=${DEB_ARCH:-"arm64"}
DEB_VERSION=${DEB_VERSION:-"bookworm"}
DEB_INSTALL_BASE_PKGS=${DEB_INSTALL_BASE_PKGS:-"ca-certificates,"}
DEB_PROXY=${DEB_PROXY:-"http://ftp.de.debian.org/debian"}
QEMU_ARCH=${QEMU_ARCH:-"aarch64"}

# Runs debootstrap stage 1 (bare rootfs creation)
function debootstrap_stage1() {
    local MOUNTPOINT="$1"
    local DEBOOTSTRAP_VARIANT=minbase
    local DEBOOTSTRAP_ARGS=(--foreign --arch=$DEB_ARCH --include="$DEB_INSTALL_BASE_PKGS" \
        --variant=$DEBOOTSTRAP_VARIANT $DEB_VERSION "$MOUNTPOINT" $DEB_PROXY)

    sh_log_info "Running debootstrap stage 1..."
    sh_log_debug debootstrap "${DEBOOTSTRAP_ARGS[@]}"
    $SUDO debootstrap "${DEBOOTSTRAP_ARGS[@]}"
}

# Finds the qemu-user-static binary for the appropriate platform ($1)
function rootfs_find_qemu_static_binfmt()
{
    if [[ -n "$PLATFORM_QEMU_ARCH" ]]; then QEMU_ARCH="$PLATFORM_QEMU_ARCH"; fi
    local INTERPRETER=
    if INTERPRETER=$(cat /proc/sys/fs/binfmt_misc/qemu-"$QEMU_ARCH" | grep '^interpreter\b'); then
        [[ -n "$INTERPRETER" ]] || return 1
        echo -n "${INTERPRETER#* }"
        return 0
    fi
    return 1
}
function rootfs_find_qemu_static_exe()
{
    local QEMU_STATIC_PATH=  # do not assign here because the error won't be returned
    if [[ -n "$PLATFORM_QEMU_ARCH" ]]; then QEMU_ARCH="$PLATFORM_QEMU_ARCH"; fi
    if QEMU_STATIC_PATH=$(which qemu-$QEMU_ARCH-static); then
        [[ -n "$QEMU_STATIC_PATH" ]] || return 1
        echo -n "$QEMU_STATIC_PATH"
        return 0
    fi
    return 1
}

## Utility function to copy qemu static binaries to the given rootfs
function rootfs_copy_qemu_static() {
    local MOUNTPOINT="${1%/}"
    local QEMU_STATIC_EXE=$(rootfs_find_qemu_static_exe || true)
    local QEMU_STATIC_BINFMT=$(rootfs_find_qemu_static_binfmt || true)
    local DIRNAME=
    if [[ -z "$QEMU_STATIC_EXE" && -z "$QEMU_STATIC_BINFMT" ]]; then
        sh_log_panic "Could not find qemu-$QEMU_ARCH-static!"
    fi
    if [[ -n "$QEMU_STATIC_EXE" ]]; then
        sh_log_debug "Found qemu static (exe): $QEMU_STATIC_EXE"
        DIRNAME=$(dirname "$QEMU_STATIC_EXE")
        $SUDO install -D -m755 -oroot -groot --target-directory="$MOUNTPOINT$DIRNAME/" "$QEMU_STATIC_EXE"
    fi
    if [[ -n "$QEMU_STATIC_BINFMT" && "$QEMU_STATIC_BINFMT" != "$QEMU_STATIC_EXE" ]]; then
        sh_log_debug "Found qemu static (binfmt_misc): $QEMU_STATIC_BINFMT"
        DIRNAME=$(dirname "$QEMU_STATIC_BINFMT")
        $SUDO install -D -m755 -oroot -groot --target-directory="$MOUNTPOINT$DIRNAME/" "$QEMU_STATIC_BINFMT"
    fi
}

# Runs debootstrap stage 2 (chrooted base package installation)
function debootstrap_stage2() {
    local MOUNTPOINT="$1"
    sh_log_info "Running debootstrap stage 2..."
    "$SRC_DIR/chroot.sh" \
        /debootstrap/debootstrap --second-stage --verbose
}

function provision_rootfs() {
    local MOUNTPOINT="$1"
    # copy provisioning files to the rootfs mountpoint
    $SUDO rsync -a --delete --chown root --chmod=755 --mkpath --exclude=".*" \
        "$SRC_DIR/" "$MOUNTPOINT/root/rpi-provisioning/"
    if declare -f -F "custom_provision_script" >/dev/null; then
        custom_provision_script "$MOUNTPOINT"
    fi
    # run the install script
    "$SRC_DIR/chroot.sh" bash "/root/rpi-provisioning/rootfs-install/install.sh"
}

sh_log_info "RootFS target: $ROOTFS_DEST"

HAS_STAGE1=
[[ -f "$ROOTFS_DEST/usr/bin/cp" || -f "$ROOTFS_DEST/debootstrap/debootstrap" ]] && HAS_STAGE1=1 || true
HAS_STAGE2=
[[ -f "$ROOTFS_DEST/usr/bin/cp" && ! -f "$ROOTFS_DEST/debootstrap/debootstrap" ]] && HAS_STAGE2=1 || true

if [[ -z "$HAS_STAGE1" ]]; then
    mkdir -p "$(dirname "$ROOTFS_DEST")"
    $SUDO mkdir -p "$ROOTFS_DEST"
    debootstrap_stage1 "$ROOTFS_DEST"
fi
if [[ -z "$HAS_STAGE2" ]]; then
    rootfs_copy_qemu_static "$ROOTFS_DEST"
    debootstrap_stage2 "$ROOTFS_DEST"
fi

# last stage: run the provisioning tasks inside the container
rootfs_copy_qemu_static "$ROOTFS_DEST"
provision_rootfs "$ROOTFS_DEST"

