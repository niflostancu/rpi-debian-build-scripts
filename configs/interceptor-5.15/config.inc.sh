# Interceptor board builder configuration (for older, 5.15 kernel + swconfig)
#

KERNEL_VERSION=${KERNEL_VERSION:-5.15}
KERNEL_BRANCH="rpi-$KERNEL_VERSION.y"
KERNEL_PATCHES_DIR=${KERNEL_PATCHES_DIR:-"$CUSTOM_CONFIG_DIR/files/kernel-$KERNEL_VERSION"}
KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"interceptor_defconfig"}

# RPI firmware / boot files
INTERCEPTOR_DTB=interceptor-rpi-cm4-$KERNEL_VERSION.dtb
[[ -v RPI_FIRMWARE_FILES[@] ]] || \
	RPI_FIRMWARE_FILES=(start4.elf fixup4.dat bcm2711-rpi-cm4.dtb)
RPI_FIRMWARE_FILES+=(/boot/$INTERCEPTOR_DTB)
RPI_CONFIG_EXTRA="device_tree=$INTERCEPTOR_DTB"$'\n'

# extra packages to install
EXTRA_PACKAGES=(firmware-realtek)
# extra .deb pkgs to install (must be manually placed in `dist/`)
SWCONFIG_DEB="$INSTALL_SRC/files/swconfig-1.0.101-aarch64.deb"
EXTRA_DEBS=("$SWCONFIG_DEB")

function rootfs_install_hook() {
	# copy custom install scripts & files to provisioning dir
	cp -ar "$CUSTOM_CONFIG_DIR/install-scripts/"* "$INSTALL_SRC/scripts/"
	cp -ar "$CUSTOM_CONFIG_DIR/files/"* "$INSTALL_SRC/files/"
}

