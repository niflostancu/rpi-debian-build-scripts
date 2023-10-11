#!/bin/bash
# need to configure raspi-firmware to use a specific ROOTPART

CUSTOM_ROOTPART="LABEL=RPI_ROOTFS"

sed -i -E 's/^(#\s*)?ROOTPART=.*$/ROOTPART='"$CUSTOM_ROOTPART"'/' /etc/default/raspi-firmware

