# Interceptor board builder configuration (latest raspberrypi downstream kernel)

KERNEL_USE_MAINLINE=${KERNEL_USE_MAINLINE:-0}
KERNEL_VERSION=${KERNEL_VERSION:-6.12}
KERNEL_BRANCH="rpi-$KERNEL_VERSION.y"
KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"bcm2711_defconfig"}
KERNEL_LOCALVERSION="-interceptor-rpi"
KERNEL_DTS_SRC="$CUSTOM_CONFIG_DIR/kernel/rpi-latest"
KERNEL_TREE_DTS_PATH="arch/arm64/boot/dts/broadcom"

if [[ "$KERNEL_USE_MAINLINE" == "1" ]]; then
	# note: mainline is not supported anymore, kept for reference
	KERNEL_BRANCH="linux-$KERNEL_VERSION.y"
	KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"$CUSTOM_CONFIG_DIR/kernel/mainline-6.5-old/interceptor_nas_6x_defconfig"}
	KERNEL_PATCHES_DIR="$CUSTOM_CONFIG_DIR/kernel/mainline-6.5-old"
	KERNEL_DTS_SRC="$CUSTOM_CONFIG_DIR/kernel/mainline-6.5-old"
	KERNEL_LOCALVERSION="-interceptor-mainline"
fi

# will copy kernel DTS to source dir (to compile them)
KERNEL_COMPILE_DTS=("interceptor-cm4.dts")
# RPI firmware / boot files
RPI_FIRMWARE_FILES=(start4.elf fixup4.dat bcm2711-rpi-4-b.dtb
	overlays/overlay_map.dtb overlays/hat_map.dtb overlays/upstream-pi4.dtbo
	overlays/dwc2.dtbo overlays/disable-bt.dtbo)
for DTS in "${KERNEL_COMPILE_DTS[@]}"; do
	DTB="${DTS%.dts}.dtb"
	RPI_FIRMWARE_FILES+=("/boot/$DTB")
done

#RPI_SKIP_BOOT_RAMDISK=1

# extra packages to install
EXTRA_PACKAGES=(firmware-realtek)
# extra .deb pkgs to install (must be manually placed in `dist/`)
#EXTRA_DEBS=()

# kernel pre-build (after patching) hook
function kernel_build_hook() {
	for DTS in "${KERNEL_COMPILE_DTS[@]}"; do
		DTB="${DTS%.dts}.dtb"
		cp -f "$KERNEL_DTS_SRC/$DTS" "$KERNEL_DEST/$KERNEL_TREE_DTS_PATH/"
		KERNEL_MAKE_GOALS+=("broadcom/$DTB")
	done
}

# kernel distrib hook to copy the generated DTBs to dist/
function kernel_dist_hook() {
	def_kernel_dist_hook
	for DTS in "${KERNEL_COMPILE_DTS[@]}"; do
		DTB="${DTS%.dts}.dtb"
		DTB_FULL="$KERNEL_DEST/$KERNEL_TREE_DTS_PATH/$DTB"
		sh_log_debug "dist $DTB"
		cp -f "$DTB_FULL" "$KERNEL_DISTRIB_DIR/"
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

