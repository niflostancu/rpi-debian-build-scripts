#!/bin/bash
# Chrootfs inside the rootfs.

set -eo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
source "$SRC_DIR/lib/common.sh"
source "$SRC_DIR/config.sh"

# dependencies
source "$SRC_DIR/lib/packages.sh"

ROOTFS_INSTALL_SRC="$SRC_DIR/rootfs-install"

# iterate through a sorted list of scripts and source them
while IFS=  read -r -d $'\0' file; do
    log_info "Running '$file'..."
    source "$ROOTFS_INSTALL_SRC/scripts/$file"

done < <(find "$ROOTFS_INSTALL_SRC/scripts/" \
    '(' -type f -iname '*.sh' ')' -printf '%P\0' | sort -n -u -z)

