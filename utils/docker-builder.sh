#!/bin/bash
# Docker-based debian builder script

set -eo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/base.sh"

@import 'load_config'

CHROOT_INSIDE_DOCKER=
CHROOT_LOOP_DEV=${CHROOT_LOOP_DEV:-/dev/loop8}

docker build --build-arg "BUILDER_UID=$(id -u)" \
	--build-arg "BUILDER_GID=$(id -g)" \
	-t "$BUILD_DOCKER_IMAGE" .

DOCKER_ARGS=(-it
	-e "CUSTOM_CONFIG=$CUSTOM_CONFIG" -e "DEBUG=$DEBUG"
	-v "$(pwd):/src:ro" -v "$(pwd)/dist:/src/dist"
	-v "$BUILD_DEST:$BUILD_DOCKER_DEST"
)

if [[ -n "$CHROOT_INSIDE_DOCKER" ]]; then
	[[ -b "$CHROOT_LOOP_DEV" ]] || $SUDO mknod -m 0660 /dev/loop8 b 7 8 || true
	$SUDO losetup -d /dev/loop8 || true
	DOCKER_ARGS+=(
		-v "$CHROOT_LOOP_DEV:$CHROOT_LOOP_DEV" -v "/dev/loop-control:/dev/loop-control"
	)
fi

sh_log_debug "Docker args: ${DOCKER_ARGS[*]}"

mkdir -p "$BUILD_DEST"
docker run "${DOCKER_ARGS[@]}" "$BUILD_DOCKER_IMAGE" "$@"

