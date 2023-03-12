#!/bin/bash
# Helper Debian apt / dpkg wrapper functions.

export DEBIAN_FRONTEND=noninteractive

DEB_APT_OPTS=()

# Installs the specified packages (only once).
function apt_install() {
    local -a pkgs=()
    while [[ $# -gt 0 ]]; do
        @silent dpkg -s "$1" || pkgs+=("$1")
        shift
    done
    if [[ ${#pkgs[@]} == 0 ]]; then return 0; fi
    log_debug "apt_install ${pkgs[@]}"
    apt-get -y "${DEB_APT_OPTS[@]}" install "${pkgs[@]}"
}

# Updates repository info
function apt_update() {
    apt-get -qq "${DEB_APT_OPTS[@]}" update
}

# Upgrades all packages
function apt_upgrade_all() {
    apt-get -y "${DEB_APT_OPTS[@]}" -y dist-upgrade
}

