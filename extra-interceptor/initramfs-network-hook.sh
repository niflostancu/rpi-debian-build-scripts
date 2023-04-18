#!/bin/sh
# Initramfs hook for setting up Interceptor board networking
# (includes swconfig + udev script for initializing the WAN / LAN switch ports)

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
manual_add_modules swconfig
manual_add_modules rtl8366_smi
manual_add_modules rtl8367b
manual_add_modules 8021q
manual_add_modules stp
manual_add_modules llc

# add swconfig + dependencies
copy_exec /usr/local/bin/swconfig /bin

# copy the udev script
mkdir -p "$DESTDIR/usr/local/bin/"
cp -p "/usr/local/bin/config-rtl8367rb.sh" "$DESTDIR/usr/local/bin/"
mkdir -p "$DESTDIR/lib/udev/rules.d/"
cp -p "/etc/udev/rules.d/90-interceptor.rules" "$DESTDIR/lib/udev/rules.d/"

