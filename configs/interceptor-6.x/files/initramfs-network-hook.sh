#!/bin/sh
# Initramfs hook for setting up Interceptor board networking
# (includes configuration & scripts for initializing the Realtek switch ports)

PREREQ=""
prereqs() {
    echo "$PREREQ"
}
case "$1" in
    prereqs)
        prereqs
        exit 0
    ;;
esac
. /usr/share/initramfs-tools/hook-functions

# add network / switch-related modules
manual_add_modules rtl8366_smi
manual_add_modules rtl8367b
manual_add_modules 8021q
manual_add_modules stp
manual_add_modules llc

