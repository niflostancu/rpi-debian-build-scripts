#!/bin/bash
# Rootfs install / distro upgrade script.

set -eo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/base.sh"

INSTALL_SRC="$(sh_get_script_path)"
DIST_DIR="$INSTALL_SRC/../dist"

@import 'load_config'
@import 'debian_packages'

if [[ "$1" == "--upgrade" ]]; then
    export DISTRO_UPGRADE=1
elif [[ -n "$1" ]]; then
    sh_log_panic "Invalid argument: $1"
fi

# rootfs install hook
if declare -f -F "rootfs_install_hook" >/dev/null; then
    sh_log_info "Running rootfs_install_hook..."
    rootfs_install_hook
fi

# iterate through a sorted list of scripts and source them
while IFS=  read -r -d $'\0' file; do
    sh_log_info "Running '$file'..."
    source "$INSTALL_SRC/scripts/$file"

done < <(find "$INSTALL_SRC/scripts/" \
    '(' -type f -iname '*.sh' ')' -printf '%P\0' | sort -n -u -z)

