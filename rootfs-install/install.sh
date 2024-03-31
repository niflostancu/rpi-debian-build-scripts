#!/bin/bash
# Rootfs install / distro upgrade script.

set -eo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
INSTALL_SRC="$SRC_DIR/rootfs-install"
DIST_DIR="$SRC_DIR/dist"

source "$SRC_DIR/lib/common.sh"

# dependencies
source "$SRC_DIR/lib/packages.sh"

if [[ "$1" == "--upgrade" ]]; then
    export DISTRO_UPGRADE=1
elif [[ -n "$1" ]]; then
    log_fatal "Invalid argument: $1"
fi

# rootfs install hook
if declare -f -F "rootfs_install_hook" >/dev/null; then
    log_info "Running rootfs_install_hook..."
    rootfs_install_hook
fi

# iterate through a sorted list of scripts and source them
while IFS=  read -r -d $'\0' file; do
    log_info "Running '$file'..."
    source "$INSTALL_SRC/scripts/$file"

done < <(find "$INSTALL_SRC/scripts/" \
    '(' -type f -iname '*.sh' ')' -printf '%P\0' | sort -n -u -z)

