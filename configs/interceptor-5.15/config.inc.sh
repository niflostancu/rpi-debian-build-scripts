# Interceptor board builder configuration (for older, 5.15 kernel + swconfig)
#

KERNEL_VERSION=${KERNEL_VERSION:-5.15}

if [[ "$KERNEL_USE_MAINLINE" == "1" ]]; then
	KERNEL_BRANCH="linux-$KERNEL_VERSION.y"
	KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"interceptor_defconfig"}
	KERNEL_PATCHES_DIR="$CUSTOM_CONFIG_DIR/files/kernel-5.15"
else
	KERNEL_BRANCH="rpi-$KERNEL_VERSION.y"
	KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"interceptor_defconfig"}
	KERNEL_PATCHES_DIR="$CUSTOM_CONFIG_DIR/files/kernel-5.15"
fi

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

# kernel distrib hook to copy the generated DTBs
function kernel_dist_hook() {
	def_kernel_dist_hook
	for file in arch/arm64/boot/dts/broadcom/{bcm2711-rpi-4-b.dtb,bcm2711-rpi-cm4.dtb,interceptor.dtb}; do
		sh_log_debug "dist $file"
		cp -f "$file" "$KERNEL_DISTRIB_DIR/"
	done
}

function rootfs_install_hook() {
	# copy custom install scripts & files to provisioning dir
	cp -ar "$CUSTOM_CONFIG_DIR/install-scripts/"* "$INSTALL_SRC/scripts/"
	cp -ar "$CUSTOM_CONFIG_DIR/files/"* "$INSTALL_SRC/files/"
}

