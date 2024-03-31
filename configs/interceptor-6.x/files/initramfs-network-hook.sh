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

# add PHY network drivers / switch-related modules
manual_add_modules veth 8021q stp llc dsa_core bridge br_netfilter genet tag_rtl8_4
manual_add_modules realtek_smi realtek_mdio rtl8366 rtl8365mb broadcom bcm_phy_lib mdio_bcm_unimac pcie_brcmstb

mkdir -p "$DESTDIR/etc/systemd/network/"
cp "/etc/systemd/network/"* "$DESTDIR/etc/systemd/network/"

