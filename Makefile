# Makefile for automated building of the full RPI distribution

DEBUG ?=
CFG ?=
# set to 1 to run natively (instead of inside Docker)
RUN_NATIVE ?=

# internal variables:
_RUN_CMD = $(if $(RUN_NATIVE),,./utils/docker-builder.sh)

export DEBUG
CUSTOM_CONFIG ?= $(CFG)
export CUSTOM_CONFIG

# build targets
.PHONY: all uboot kernel rootfs image
all: uboot kernel rootfs image

uboot:
	$(_RUN_CMD) ./build-uboot.sh

kernel:
	$(_RUN_CMD) ./build-kernel.sh

rootfs:
	# always run on host (since systemd-nspawn doesn't work inside the container)
	./build-rootfs.sh

image:
	./build-image.sh

