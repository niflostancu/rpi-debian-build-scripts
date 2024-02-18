#!/bin/bash
# Installs the kernel and updates the boot partition

if [[ "$SKIP_KERNEL" =~ ^1|y(es)?$ ]]; then return 0; fi

# configuration variables
# 'auto' will install from .debs if present in dist/ dir,
# falling back from repo otherwise
KERNEL_FROM_DEBS=${KERNEL_FROM_DEBS:-auto}
KERNEL_FROM_REPO=${KERNEL_FROM_REPO:-auto}
# apt repo packages to install
[[ -v INSTALL_KERNEL_PACKAGES[@] ]] || 
    INSTALL_KERNEL_PACKAGES=(linux-image-generic linux-headers-generic)

if [[ "$KERNEL_FROM_DEBS" =~ ^1|y(es)?|auto$ ]]; then
    # debs to install
    log_info "Searching for linux kernel .debs to install..."
    KERNEL_PKG_PREFIXES=(linux-image- linux-headers-)
    KERNEL_FILES=()
    if [[ -d "$KERNEL_DISTRIB_DIR" ]]; then
        for prefix in "${KERNEL_PKG_PREFIXES[@]}"; do
            _FIND_ARGS=(-name "$prefix*" -not -iname '*-dbg_*')
            _KERNEL_FILE=$( cd "$KERNEL_DISTRIB_DIR"; find . "${_FIND_ARGS[@]}" | sort -r --version-sort | head -1 )
            if [[ -z "$_KERNEL_FILE" ]]; then
                log_error "Coult not find package for $prefix !"
            fi
            KERNEL_FILES+=("$_KERNEL_FILE")
        done
    fi
    if [[ -n "${KERNEL_FILES[*]}" ]]; then
        log_info "Installing .debs: ${KERNEL_FILES[*]}"
        # [Re]Install kernel packages (initramfs will be generated and hooks run)
        ( cd "$KERNEL_DISTRIB_DIR"; dpkg -i "${KERNEL_FILES[@]}" )
        # kernel .debs found, clear repo install flag 
        KERNEL_FROM_REPO=0
    else
        if [[ "$KERNEL_FROM_DEBS" == "auto" && "$KERNEL_FROM_REPO" =~ ^1|y(es)|auto?$ ]]; then
            log_info "Unable to find kernel packages inside $KERNEL_DISTRIB_DIR, installing repo kernel!"
        else
            log_error "Unable to find kernel packages inside $KERNEL_DISTRIB_DIR!"
            return 1
        fi
    fi
fi

if [[ "$KERNEL_FROM_REPO" =~ ^1|y(es)?|auto$ ]]; then
    # install kernel from the repository
    log_info "Installing kernel packages from repo: ${INSTALL_KERNEL_PACKAGES[*]}"
    apt_install "${INSTALL_KERNEL_PACKAGES[@]}"
fi

