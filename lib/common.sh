#!/bin/bash
# Common utility functions.

source "$SRC_DIR/lib/utils.sh"

# load user config first
[[ ! -f "$SRC_DIR/config.sh" ]] || source "$SRC_DIR/config.sh"

# include CUSTOM_CONFIG overlay (if specified)
[[ -z "$CUSTOM_CONFIG" ]] || CUSTOM_CONFIG_DIR="$SRC_DIR/configs/$CUSTOM_CONFIG"
[[ -z "$CUSTOM_CONFIG_DIR" ]] || source "$CUSTOM_CONFIG_DIR/config.inc.sh"

# finally, load the defaults
# user config may wish to prevent the default config from loading
[[ -n "$SKIP_DEFAULT_CONFIG" ]] || source "$SRC_DIR/config.default.sh"

