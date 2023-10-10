#!/bin/bash
# Extra config (custom scripts)

if declare -f -F "custom_rootfs_script" >/dev/null; then
    log_info "Running custom_rootfs_script..."
    custom_rootfs_script
fi

