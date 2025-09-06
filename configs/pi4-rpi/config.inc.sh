# Debian rootfs + raspberrypi official fork kernel (RPI4 config)

KERNEL_VERSION=${KERNEL_VERSION:-6.12}
KERNEL_BRANCH="rpi-$KERNEL_VERSION.y"
KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"bcm2711_defconfig"}

# add required firmware + some overlays
RPI_FIRMWARE_FILES=(start4.elf fixup4.dat bcm2711-rpi-4-b.dtb
	overlays/overlay_map.dtb overlays/hat_map.dtb overlays/upstream-pi4.dtbo
	overlays/dwc2.dtbo overlays/disable-bt.dtbo)

function rootfs_install_hook() {
	# copy custom install scripts to exec. dir
	# cp -ar "$CUSTOM_CONFIG_DIR/install-scripts/"* "$INSTALL_SRC/scripts/"
	true
}

