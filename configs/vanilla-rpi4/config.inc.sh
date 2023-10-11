# Official firmware + kernel Debian configuration

# install vanilla kernel & firmware
EXTRA_PACKAGES=(raspi-firmware linux-image-generic linux-headers-generic linux-libc-dev)
SKIP_BOOT_FILES=y

function rootfs_install_hook() {
	# copy custom install scripts to exec. dir
	rsync -a --chmod=755 "$CUSTOM_CONFIG_DIR/install-scripts/" \
		"$INSTALL_SRC/scripts/"
}

