#!/bin/bash
# Common host scripts configuration module

# export parent source directory to called scripts
SRC_DIR="$(dirname -- "$(sh_get_script_path)")"
export SRC_DIR

CONFIGS="$SRC_DIR/configs"
CONFIG_SNIPPETS="$CONFIGS/_snippets"
SKIP_DEFAULT_CONFIG=${SKIP_DEFAULT_CONFIG:-}

# load user config first
[[ ! -f "$SRC_DIR/config.sh" ]] || source "$SRC_DIR/config.sh"

# include CUSTOM_CONFIG overlay (if specified)
[[ -z "$CUSTOM_CONFIG" ]] || CUSTOM_CONFIG_DIR="$SRC_DIR/configs/$CUSTOM_CONFIG"
[[ -z "$CUSTOM_CONFIG_DIR" ]] || source "$CUSTOM_CONFIG_DIR/config.inc.sh"

# finally, load the defaults
# user config may wish to prevent the default config from loading
[[ -n "$SKIP_DEFAULT_CONFIG" ]] || source "$SRC_DIR/config.default.sh"

