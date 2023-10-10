# Interceptor board builder configuration (for older, 5.15 kernel + swconfig)
#

KERNEL_PATCHES_DIR="$CUSTOM_CONFIG_DIR/kernel-5.15"
KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"interceptor_defconfig"}

# RPI boot files (to be copied in place by rootfs-extra-install.sh)
RPI_FIRMWARE_FILES+=(/boot/interceptor.dtb)
RPI_CONFIG_EXTRA="device_tree=interceptor.dtb"$'\n'

# extra packages to install
EXTRA_PACKAGES=(firmware-realtek)
# extra .deb pkgs to install (must be manually placed in `dist/`)
EXTRA_DEBS=(swconfig-1.0.101-aarch64.deb)

# Custom provisioning script that copies built kernel from KERNEL_DEST
# to the rootfs.
function custom_provision_script() {
	true
}

# Extra installation hook (to run custom scripts)
function custom_rootfs_script() {
	bash "$CUSTOM_CONFIG_DIR/rootfs-extra-install.sh"
}

