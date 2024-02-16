#!/bin/bash
# Cross-compiles a raspberry pi kernel (with optional patches).

set -eo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
source "$SRC_DIR/lib/common.sh"

[[ -n "$KERNEL_DEST" ]] || log_fatal "No KERNEL_DEST given!"
KERNEL_BRANCH=${KERNEL_BRANCH:-"unknown_branch"}
KERNEL_ARCH=${KERNEL_ARCH:-"arm64"}
KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"unknown_defconfig"}
KERNEL_LOCALVERSION=${KERNEL_LOCALVERSION:-'-rpi'}

if [[ -z "$KERNEL_GIT_URL" ]]; then
    KERNEL_GIT_URL="https://github.com/raspberrypi/linux"
    if [[ "$KERNEL_USE_MAINLINE" == "1" ]]; then
        KERNEL_GIT_URL="https://github.com/torvalds/linux"
    fi
fi

if [[ ! -d "$KERNEL_DEST" ]]; then
    mkdir -p "$(dirname "$KERNEL_DEST")"
    git clone --depth=1 "$KERNEL_GIT_URL" --branch "$KERNEL_BRANCH" \
        --single-branch "$KERNEL_DEST"
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
KERNEL_MAKE_GOALS=(Image modules dtbs)
KERNEL_PACKAGE_GOALS=(bindeb-pkg)

# kernel configuration phase
make "${MAKE_ARGS[@]}" "$KERNEL_DEFCONFIG"
if [[ -n "$KERNEL_LOCALVERSION" ]]; then
    ./scripts/config --set-str LOCALVERSION "$KERNEL_LOCALVERSION"
fi

# kernel build hook
if declare -f -F "kernel_build_hook" >/dev/null; then
    log_info "Running kernel_build_hook..."
    kernel_build_hook "$KERNEL_DEST"
fi

# compilation phase
make "${MAKE_ARGS[@]}" -j "$KERNEL_MAKE_THREADS" "${KERNEL_MAKE_GOALS[@]}"

# finally: generate .dep with binaries
make "${MAKE_ARGS[@]}" -j "$KERNEL_MAKE_THREADS" "${KERNEL_PACKAGE_GOALS[@]}"

# kernel distribute hook
if declare -f -F "kernel_dist_hook" >/dev/null; then
    log_info "Running kernel_dist_hook..."
    kernel_dist_hook "$KERNEL_DEST"
fi

log_info "Kernel build finished!"

