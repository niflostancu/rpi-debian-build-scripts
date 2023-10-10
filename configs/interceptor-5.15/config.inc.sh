# Interceptor board builder configuration (for older, 5.15 kernel + swconfig)
#

KERNEL_PATCHES_DIR="$CUSTOM_CONFIG_DIR/kernel-5.15"
KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"interceptor_defconfig"}

# RPI firmware / boot files
INTERCEPTOR_DTB=interceptor-rpi-cm4-5.15.dtb
RPI_FIRMWARE_FILES+=(/boot/$INTERCEPTOR_DTB)
RPI_CONFIG_EXTRA="device_tree=$INTERCEPTOR_DTB"$'\n'

# extra packages to install
EXTRA_PACKAGES=(firmware-realtek)
# extra .deb pkgs to install (must be manually placed in `dist/`)
SWCONFIG_DEB=swconfig-1.0.101-aarch64.deb
EXTRA_DEBS=($SWCONFIG_DEB)

# Custom provisioning script that copies built kernel from KERNEL_DEST
# to the rootfs.
function custom_provision_script() {
	true
}

# Extra installation hook (to run custom scripts)
function custom_rootfs_script() {
	source "$CUSTOM_CONFIG_DIR/rootfs-extra-install.sh"
}

