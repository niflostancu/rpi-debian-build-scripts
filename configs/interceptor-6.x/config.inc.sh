# Interceptor board builder configuration (for older, 5.15 kernel + swconfig)
#

KERNEL_USE_MAINLINE=${KERNEL_USE_MAINLINE:-1}
KERNEL_VERSION=${KERNEL_VERSION:-6.6}
KERNEL_LOCALVERSION="-rpi-interceptor"

if [[ "$KERNEL_USE_MAINLINE" == "1" ]]; then
	KERNEL_BRANCH="linux-$KERNEL_VERSION.y"
	KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"$CUSTOM_CONFIG_DIR/files/kernel-6.5/interceptor_nas_6x_defconfig"}
	KERNEL_PATCHES_DIR="$CUSTOM_CONFIG_DIR/files/kernel-6.5"
else
	KERNEL_VERSION=${KERNEL_VERSION:-6.5}
	KERNEL_BRANCH="rpi-$KERNEL_VERSION.y"
	KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"bcm2711_defconfig"}
	KERNEL_PATCHES_DIR="$CUSTOM_CONFIG_DIR/files/kernel-6.5"
fi

# RPI firmware / boot files
INTERCEPTOR_DTB_FROM="$INSTALL_SRC/files/kernel-6.5/interceptor.dtb"
INTERCEPTOR_DTB_NAME=interceptor-rpi-cm4-${KERNEL_VERSION}.dtb
RPI_FIRMWARE_FILES=(start4.elf fixup4.dat bcm2711-rpi-4-b.dtb
	overlays/overlay_map.dtb overlays/hat_map.dtb overlays/upstream-pi4.dtbo
	overlays/dwc2.dtbo overlays/disable-bt.dtbo)
# also copy interceptor.dtb (note the absolute path)
RPI_FIRMWARE_FILES+=("/boot/$INTERCEPTOR_DTB_NAME")
RPI_CONFIG_EXTRA="device_tree=$INTERCEPTOR_DTB_NAME"$'\n'

#RPI_SKIP_BOOT_RAMDISK=1

# extra packages to install
EXTRA_PACKAGES=(firmware-realtek)
# extra .deb pkgs to install (must be manually placed in `dist/`)
#EXTRA_DEBS=()

# kernel pre-build (after patching) hook
function kernel_build_hook() {
	true
}

# kernel distrib hook to copy the generated DTBs to dist/
function kernel_dist_hook() {
	def_kernel_dist_hook
	for file in arch/arm64/boot/dts/broadcom/{bcm2711-rpi-4-b.dtb,bcm2711-rpi-cm4-io.dtb,interceptor.dtb}; do
		log_debug "dist $file"
		cp -f "$file" "$KERNEL_DISTRIB_DIR/"
	done
}

function rootfs_install_hook() {
	# copy custom install scripts & files to provisioning dir
	cp -ar "$CUSTOM_CONFIG_DIR/install-scripts/"* "$INSTALL_SRC/scripts/"
	cp -ar "$CUSTOM_CONFIG_DIR/files/"* "$INSTALL_SRC/files/"
}

function image_build_hook() {
	export BUILD_FULL_IMAGE=1
	chmod +x "$CUSTOM_CONFIG_DIR/copy-image-files.sh"
	"$CUSTOM_CONFIG_DIR/copy-image-files.sh" "$1/$RPI_FIRMWARE_DIR"
}

