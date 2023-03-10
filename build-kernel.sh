#!/bin/bash
# Cross-compiles a raspberry pi kernel (with optional patches).

set -eo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
source "$SRC_DIR/lib/common.sh"
source "$SRC_DIR/config.sh"

KERNEL_BRANCH=${KERNEL_BRANCH:-"rpi-5.15.y"}
KERNEL_ARCH=${KERNEL_DEFCONFIG:-"arm64"}
KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"interceptor_defconfig"}
KERNEL_LOCALVERSION=${KERNEL_LOCALVERSION:-'-rpi-nas'}

if [[ ! -d "$KERNEL_DEST" ]]; then
    mkdir -p "$(basename "$KERNEL_DEST")"
    git clone --depth=1 https://github.com/raspberrypi/linux \
        --branch "$KERNEL_BRANCH" --single-branch "$KERNEL_DEST"
fi

cd "$KERNEL_DEST"
pwd

for pfile in "$SRC_DIR/kernel-patches/linux-"*.patch; do
    if ! patch -R -p1 -s -f --dry-run <"$pfile"; then
        log_debug "Applying patch $pfile"
        patch -p1 < "$pfile"
    fi
done

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

