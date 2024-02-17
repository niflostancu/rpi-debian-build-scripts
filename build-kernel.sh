#!/bin/bash
# Cross-compiles a raspberry pi kernel (with optional patches).

set -eo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
source "$SRC_DIR/lib/common.sh"

# env / cmdline args
SKIP_BUILD="${SKIP_BUILD:-1}"

# config variables
[[ -n "$KERNEL_DEST" ]] || log_fatal "No KERNEL_DEST given!"
KERNEL_BRANCH=${KERNEL_BRANCH:-"unknown_branch"}
KERNEL_ARCH=${KERNEL_ARCH:-"arm64"}
KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"unknown_defconfig"}
KERNEL_LOCALVERSION=${KERNEL_LOCALVERSION:-'-rpi'}

if [[ -z "$KERNEL_GIT_URL" ]]; then
    KERNEL_GIT_URL="https://github.com/raspberrypi/linux"
    if [[ "$KERNEL_USE_MAINLINE" == "1" ]]; then
        KERNEL_GIT_URL="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
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
    log_info "Using LOCALVERSION='$KERNEL_LOCALVERSION'"
fi

# kernel build hook
if declare -f -F "kernel_build_hook" >/dev/null; then
    log_info "Running kernel_build_hook..."
    kernel_build_hook "$KERNEL_DEST"
fi

# compilation phase
if [[ -z "$SKIP_BUILD" ]]; then
    make "${MAKE_ARGS[@]}" -j "$KERNEL_MAKE_THREADS" "${KERNEL_MAKE_GOALS[@]}"
fi

# generate binary packages
make "${MAKE_ARGS[@]}" -j "$KERNEL_MAKE_THREADS" "${KERNEL_PACKAGE_GOALS[@]}"
# distribute packages
KERNEL_PACKAGE_PATTERNS=("linux-image-*.deb" "linux-headers-*.deb" "linux-libc-dev*.deb")
function def_kernel_dist_hook() {
    # note: don't use local vars due to subshell invocations
    local _FIND_ARGS=()
    local _DIST_FILES=()
    for pat in "${KERNEL_PACKAGE_PATTERNS[@]}"; do
        [[ "${#_FIND_ARGS[@]}" == '0' ]] || _FIND_ARGS+=('-or')
        _FIND_ARGS+=(-name "$pat")
    done
    log_debug "find args: ${_FIND_ARGS[@]}"
    # note: kernel package target outputs its files to build parent dir
    mapfile -d '' _DIST_FILES < <(find ../ '(' "${_FIND_ARGS[@]}" ')' -print0)
    log_debug "Dist files: ${_DIST_FILES[@]}"
    mkdir -p "$KERNEL_DISTRIB_DIR/"
    for file in "${_DIST_FILES[@]}"; do
        log_debug "dist: $file"
        cp -f "$file" "$KERNEL_DISTRIB_DIR/"
    done
}

# kernel distribute hook
if declare -f -F "kernel_dist_hook" >/dev/null; then
    log_info "Running kernel_dist_hook..."
    kernel_dist_hook "$KERNEL_DEST"
else
    def_kernel_dist_hook
fi

log_info "Kernel build finished!"

