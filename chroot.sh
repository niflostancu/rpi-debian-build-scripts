#!/bin/bash
# Chrootfs inside the rootfs.

set -eo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
source "$SRC_DIR/lib/common.sh"

CHROOT_USER=${CHROOT_USER:-root}
CHROOT_HOME=${CHROOT_HOME:-/root}
CHROOT_LOOP_DEV=${CHROOT_LOOP_DEV:-/dev/loop8}
NSPAWN_ARGS=(
    --as-pid2 --resolv-conf=copy-host
    --capability=CAP_MKNOD --capability=all
    --bind=/dev/loop-control --bind=$CHROOT_LOOP_DEV
)
CHROOT_PATH=/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin
CHROOT_ENV=(
    TERM="$TERM" PS1='\u:\w\$ ' DEBUG=$DEBUG
    USER="$CHROOT_USER" HOME="$CHROOT_HOME"
    CUSTOM_CONFIG="$CUSTOM_CONFIG"
)
while [[ $# > 0 ]]; do
    case "$1" in
        --prepend-path)
            CHROOT_PATH="$2:$CHROOT_PATH"; shift ;;
        --env)
            CHROOT_ENV+=("$2"); shift ;;
        --bind*)
            NSPAWN_ARGS+=("$1") ;;
        --volatile*)
            NSPAWN_ARGS+=("$1") ;;
        *)
            break ;;
    esac
    shift
done

[[ -n "$ROOTFS_DEST" ]] || log_fatal "No ROOTFS_DEST given!"

# default chroot command
if [[ "$#" == 0 ]]; then
    set -- "bash"
fi

export SYSTEMD_SECCOMP=0

log_info "Chrooting into '$ROOTFS_DEST'"
log_debug systemd-nspawn "${NSPAWN_ARGS[@]}" -D "$ROOTFS_DEST" \
    env -i "${CHROOT_ENV[@]}" "$@"

# this is required for providing the rootfs with an usable loop device,
# used for creating the build.img ramdisk from initrd hook.
[[ -b "$CHROOT_LOOP_DEV" ]] || $SUDO mknod -m 0660 /dev/loop8 b 7 8 || true
$SUDO losetup -d /dev/loop8 || true

$SUDO systemd-nspawn "${NSPAWN_ARGS[@]}" -D "$ROOTFS_DEST" \
    env -i "${CHROOT_ENV[@]}" "$@"

# forced cleanup
$SUDO losetup -d /dev/loop8 2>/dev/null || true

