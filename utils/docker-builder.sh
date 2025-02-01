#!/bin/bash
# Docker-based debian builder script

set -eo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/base.sh"

@import 'load_config'


docker build --build-arg "BUILDER_UID=$(id -u)" \
	--build-arg "BUILDER_GID=$(id -g)" \
	-t "$BUILD_DOCKER_IMAGE" .

DOCKER_ARGS=(-it
	-e "CUSTOM_CONFIG=$CUSTOM_CONFIG" -e "DEBUG=$DEBUG"
	-v "$(pwd):/src:ro" -v "$(pwd)/dist:/src/dist"
	-v "$BUILD_DEST:$BUILD_DOCKER_DEST"
)

sh_log_debug "Docker args: ${DOCKER_ARGS[*]}"

docker run "${DOCKER_ARGS[@]}" "$BUILD_DOCKER_IMAGE" "$@"

