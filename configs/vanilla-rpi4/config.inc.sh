# Official firmware + kernel Debian configuration

# install vanilla kernel & firmware
INSTALL_KERNEL_PACKAGES=(linux-image-arm64 linux-headers-arm64)
EXTRA_PACKAGES=(raspi-firmware linux-libc-dev)

RPI_SKIP_IMAGE_GEN=1

function rootfs_install_hook() {
	# copy custom install scripts to exec. dir
	cp -ar "$CUSTOM_CONFIG_DIR/install-scripts/"* "$INSTALL_SRC/scripts/"
}

