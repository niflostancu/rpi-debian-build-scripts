#!/bin/bash
# Common utility functions.

declare -g -A LOG_LEVEL_COLORS=(
    [_reset]="0m"
    [debug]="36m" # cyan
    [info]="1;32m"  # bold, green
    [err]="1;31m"  # bold, red
)
SCRIPT_NAME=`basename "$0"`

# test if the terminal supports colors
TERM_COLORS=${TERM_COLORS:-}
if test -t 1; then
    _term_ncolors=$(tput colors 2>/dev/null || true)
    if test -z "$_term_ncolors"; then
        [[ "$TERM" =~ *"color"* ]] && TERM_COLORS=1 || true
    elif test $_term_ncolors -ge 8; then
        TERM_COLORS=1
    fi
fi
export TERM_COLORS

function log_color_print() {
    local LEVEL="$1"; shift
    local ESC=$'\033['
    if [[ -z "$TERM_COLORS" ]]; then
        echo "$*"; return
    fi
    echo "$ESC${LOG_LEVEL_COLORS["$LEVEL"]}$*$ESC${LOG_LEVEL_COLORS["_reset"]}";
}

function _log_internal() {
    local LEVEL="$1"; shift
    if [[ "$LOG_TO_SYSLOG" == "1" ]]; then
        logger -p local0."$LEVEL" -t "$SCRIPT_NAME" "[${LEVEL^^}] $*"; return 0
    fi
    log_color_print "$LEVEL" "$SCRIPT_NAME: $*"
}

function log_debug() {
    [[ -n "$DEBUG" ]] || return 0
    _log_internal "debug" "$@"
}
function log_info() { _log_internal "info" "$@"; }
function log_error() { _log_internal "err" "$@" >&2; }
function log_fatal() { _log_internal "err" "$@" >&2; exit 1; }

function @silent() {
    "$@" >/dev/null 2>&1
}

# Check whether the current user is root
function check_user_root() {
    if [[ $EUID -ne 0 ]]; then
        log_fatal "this script must be run as root!"
    fi
}

# load user config first
[[ ! -f "$SRC_DIR/config.sh" ]] || source "$SRC_DIR/config.sh"

# include CUSTOM_CONFIG overlay (if specified)
[[ -z "$CUSTOM_CONFIG" ]] || CUSTOM_CONFIG_DIR="$SRC_DIR/configs/$CUSTOM_CONFIG"
[[ -z "$CUSTOM_CONFIG_DIR" ]] || source "$CUSTOM_CONFIG_DIR/config.inc.sh"

# finally, load the defaults
# user config may wish to prevent the default config from loading
[[ -n "$SKIP_DEFAULT_CONFIG" ]] || source "$SRC_DIR/config.default.sh"

