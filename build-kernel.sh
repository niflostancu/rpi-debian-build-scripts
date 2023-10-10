#!/bin/bash
# Cross-compiles a raspberry pi kernel (with optional patches).

set -eo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
source "$SRC_DIR/lib/common.sh"
source "$SRC_DIR/config.sh"

KERNEL_DEST=${KERNEL_DEST:-"$BUILD_DEST/kernel-build"}
KERNEL_BRANCH=${KERNEL_BRANCH:-"rpi-5.15.y"}
KERNEL_ARCH=${KERNEL_ARCH:-"arm64"}
KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"bcm2711_defconfig"}
KERNEL_LOCALVERSION=${KERNEL_LOCALVERSION:-'-rpi-nas'}

if [[ ! -d "$KERNEL_DEST" ]]; then
    mkdir -p "$(dirname "$KERNEL_DEST")"
    git clone --depth=1 https://github.com/raspberrypi/linux \
        --branch "$KERNEL_BRANCH" --single-branch "$KERNEL_DEST"
fi

cd "$KERNEL_DEST"
pwd

if [[ -n "$KERNEL_PATCHES_DIR" ]] && [[ -d "$KERNEL_PATCHES_DIR" ]]; then
    log_info "Using patch dir: $KERNEL_PATCHES_DIR"
    for pfile in "$KERNEL_PATCHES_DIR/"*.patch; do
        # idempotency: check if patch has already been applied
        if ! patch -R -p1 -s -f --dry-run <"$pfile"; then
            log_debug "Applying patch $pfile"
            patch -p1 < "$pfile"
        fi
    done
fi

if [[ "$CLEAN" == "1" ]]; then
    make clean
fi

MAKE_ARGS=(ARCH="$KERNEL_ARCH" CROSS_COMPILE="$CROSS_COMPILER")

# kernel configuration phase
make "${MAKE_ARGS[@]}" "$KERNEL_DEFCONFIG"
if [[ -n "$KERNEL_LOCALVERSION" ]]; then
    ./scripts/config --set-str LOCALVERSION "$KERNEL_LOCALVERSION"
fi

# compilation phase
make "${MAKE_ARGS[@]}" -j "$KERNEL_MAKE_THREADS" Image modules dtbs

# finally: generate .dep with binaries
make "${MAKE_ARGS[@]}" -j "$KERNEL_MAKE_THREADS" bindeb-pkg

