#!/bin/bash
# Cross-compiles a Raspberry Pi u-boot.

set -eo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/base.sh"

@import 'load_config'

CLEAN=${CLEAN:-}

[[ -n "$UBOOT_DEST" ]] || sh_log_panic "No UBOOT_DEST given!"
UBOOT_GIT=${UBOOT_GIT:-"https://github.com/u-boot/u-boot.git"}
UBOOT_BRANCH=${UBOOT_BRANCH:-"unknown_branch"}
UBOOT_DEFCONFIG=${UBOOT_DEFCONFIG:-"unknown_defconfig"}
UBOOT_MAKE_THREADS=${UBOOT_MAKE_THREADS:-4}

if [[ ! -d "$UBOOT_DEST" ]]; then
    mkdir -p "$(dirname "$UBOOT_DEST")"
    git clone --branch "$UBOOT_BRANCH" "$UBOOT_GIT" "$UBOOT_DEST"
fi

cd "$UBOOT_DEST"
pwd

if [[ -n "$UBOOT_PATCHES_DIR" ]] && [[ -d "$UBOOT_PATCHES_DIR" ]]; then
    sh_log_info "Using patch dir: $UBOOT_PATCHES_DIR"
    for pfile in "$UBOOT_PATCHES_DIR/"*.patch; do
        # idempotency: check if patch has already been applied
        if ! patch -R -p1 -s -f --dry-run <"$pfile"; then
            sh_log_debug "Applying patch $pfile"
            patch -p1 < "$pfile"
        fi
    done
fi

if [[ "$CLEAN" == "1" ]]; then
    make clean
fi

MAKE_ARGS=(CROSS_COMPILE="$CROSS_COMPILER")

[[ -f ".config" ]] || make "${MAKE_ARGS[@]}" "$UBOOT_DEFCONFIG"
[[ ! -f ".makemenuconfig" ]] || make "${MAKE_ARGS[@]}" "menuconfig"

# u-boot configuration phase

# compilation phase
make "${MAKE_ARGS[@]}" -j "$UBOOT_MAKE_THREADS"

sh_log_info "U-boot successfully built!"
ls -lh "$UBOOT_DEST/u-boot.bin"

