#!/bin/bash
# Cross-compiles a raspberry pi kernel (with optional patches).

set -eo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/base.sh"

@import 'load_config'

# env / cmdline args
SKIP_BUILD="${SKIP_BUILD:-}"

# config variables
[[ -n "$KERNEL_DEST" ]] || sh_log_panic "No KERNEL_DEST given!"
KERNEL_BRANCH=${KERNEL_BRANCH:-"unknown_branch"}
KERNEL_ARCH=${KERNEL_ARCH:-"arm64"}
KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"unknown_defconfig"}
KERNEL_LOCALVERSION=${KERNEL_LOCALVERSION:-'-rpi'}
KERNEL_DPKG_VERSION=${KERNEL_DPKG_VERSION:-'1+custom'}

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
    sh_log_info "Using patch dir: $KERNEL_PATCHES_DIR"
    for pfile in "$KERNEL_PATCHES_DIR/"*.patch; do
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

MAKE_ARGS=(ARCH="$KERNEL_ARCH" CROSS_COMPILE="$CROSS_COMPILER")
KERNEL_MAKE_GOALS=(Image modules dtbs)
KERNEL_PACKAGE_GOALS=(bindeb-pkg)

# kernel configuration phase
if [[ "$KERNEL_DEFCONFIG" == */* ]]; then
    # load defconfig from provided file
    CONFIG_NAME=$(basename "$KERNEL_DEFCONFIG")
    cp -f "$KERNEL_DEFCONFIG" "arch/$KERNEL_ARCH/configs/$CONFIG_NAME"
    make "${MAKE_ARGS[@]}" "$CONFIG_NAME"
else
    make "${MAKE_ARGS[@]}" "$KERNEL_DEFCONFIG"
fi

if [[ -n "$KERNEL_LOCALVERSION" ]]; then
    ./scripts/config --set-str LOCALVERSION ""
    sed -i "s|CONFIG_LOCALVERSION_AUTO=.*|CONFIG_LOCALVERSION_AUTO=n|" .config
    export LOCALVERSION="$KERNEL_LOCALVERSION"
    sh_log_info "Using LOCALVERSION='$KERNEL_LOCALVERSION'"
fi

# kernel build hook
if declare -f -F "kernel_build_hook" >/dev/null; then
    sh_log_info "Running kernel_build_hook..."
    kernel_build_hook "$KERNEL_DEST"
fi

# compilation phase
if [[ -z "$SKIP_BUILD" ]]; then
    sh_log_debug "kernel make:" "${MAKE_ARGS[@]}" -j "$KERNEL_MAKE_THREADS" "${KERNEL_MAKE_GOALS[@]}"
    make "${MAKE_ARGS[@]}" -j "$KERNEL_MAKE_THREADS" "${KERNEL_MAKE_GOALS[@]}"
fi

# generate binary packages
KERNEL_DPKG_VERSION="$(make kernelversion)-$KERNEL_DPKG_VERSION"
make "${MAKE_ARGS[@]}" -j "$KERNEL_MAKE_THREADS" \
    KDEB_PKGVERSION="${KERNEL_DPKG_VERSION}" "${KERNEL_PACKAGE_GOALS[@]}"
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
    sh_log_debug "find args: ${_FIND_ARGS[@]}"
    # note: kernel package target outputs its files to build parent dir
    mapfile -d '' _DIST_FILES < <(find ../ -maxdepth 1 -mindepth 1 \
        '(' "${_FIND_ARGS[@]}" ')' -print0)
    sh_log_debug "Dist files: ${_DIST_FILES[@]}"
    mkdir -p "$KERNEL_DISTRIB_DIR/"
    for file in "${_DIST_FILES[@]}"; do
        sh_log_debug "dist: $file"
        cp -f "$file" "$KERNEL_DISTRIB_DIR/"
    done
}

# kernel distribute hook
if declare -f -F "kernel_dist_hook" >/dev/null; then
    sh_log_info "Running kernel_dist_hook..."
    kernel_dist_hook "$KERNEL_DEST"
else
    def_kernel_dist_hook
fi

sh_log_info "Kernel build finished!"

