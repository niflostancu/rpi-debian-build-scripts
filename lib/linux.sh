#!/bin/bash
: <<DOCS
Linux/system administration routines.
https://github.com/niflostancu/sh-lib

* user/group creation routines & root check;
* change permissions routines;

DOCS

# if the effective user of this script isn't root, it will exit with error
# Usage: `sh_user_must_be_root`
function sh_user_must_be_root() {
	if [[ $EUID -ne 0 ]]; then
		sh_log_panic "this script must be run as root!"
	fi
}

# idempotent creation of a Linux user with specific ID+GID
# Usage: `sh_create_user NAME ID`
function sh_create_user() {
	local NAME="$1" IDS="$2" _SHELL="${SHELL:-/bin/bash}"
	id -g "$NAME" >/dev/null 2>&1 || groupadd -g "$IDS" "$NAME"
	id -u "$NAME" >/dev/null 2>&1 || \
		useradd -m -s "$_SHELL" -u "$IDS" -g "$IDS" "$NAME"
}

# recursively change permissions + owner for the given path
# Usage: `sh_change_perms OWNER[:GROUP] PERMS DESTINATION`
function sh_change_perms() {
	local OWNER="$1" PERMS="$2" DESTINATION="$3"
	chmod -R "$PERMS" "$DESTINATION"
	chown -R "$OWNER" "$DESTINATION"
}

