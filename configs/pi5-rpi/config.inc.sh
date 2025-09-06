# Debian rootfs + raspberrypi official fork kernel (RPI4 config)

KERNEL_VERSION=${KERNEL_VERSION:-6.12}
KERNEL_BRANCH="rpi-$KERNEL_VERSION.y"
KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-"bcm2712_defconfig"}

# add required firmware + some overlays
RPI_FIRMWARE_FILES=(start4.elf fixup4.dat bcm2712-rpi-5-b.dtb bcm2712d0-rpi-5-b.dtb
	overlays/overlay_map.dtb overlays/hat_map.dtb overlays/disable-bt.dtbo
	overlays/pciex1-compat-pi5.dtbo overlays/pcie-32bit-dma-pi5.dtbo 
	overlays/pcie-32bit-dma.dtbo overlays/dwc2.dtbo)

function rootfs_install_hook() {
	# copy custom install scripts to exec. dir
	#cp -ar "$CUSTOM_CONFIG_DIR/install-scripts/"* "$INSTALL_SRC/scripts/"
	true
}

