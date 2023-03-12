#!/bin/bash
# Extra config (custom scripts)

if declare -f -F "custom_script" >/dev/null; then
    log_info "Running custom_script..."
    custom_script
fi

