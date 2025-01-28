#!/bin/bash
# Extra config (custom scripts)

if declare -f -F "rootfs_extra_script" >/dev/null; then
    sh_log_info "Running rootfs_extra_script..."
    rootfs_extra_script
fi

# install extra packages either from repo or from .debs
if [[ -n "$EXTRA_PACKAGES" ]]; then
    apt_install "${EXTRA_PACKAGES[@]}"
fi
if [[ -n "$EXTRA_DEBS" ]]; then
    ( cd "$DIST_DIR"; 
      dpkg -i "${EXTRA_DEBS[@]}" || apt-get -f -y install; )
fi

