#!/bin/bash
: <<'DOCS'
Base bash functions library
https://github.com/niflostancu/sh-lib

* color print / debug routines;
* captioned / indented / silent printing of a function's output;
* basic string manipulation / interpolation routines;

DOCS

## Library customization vars
# disable sh_* aliases (e.g., @import)
SH_NO_ALIASES=${SH_NO_ALIASES:-}
# set to 1 to force terminal colors
TERM_COLORS=${TERM_COLORS:-}
# log prefix environment var: prepended to all logged messages
SH_LOG_PREFIX=${SH_LOG_PREFIX:-}
# debug enable environment var (if non-null)
DEBUG=${DEBUG:-}
# enable internal function debugging
SH_DEBUG_INT=${SH_DEBUG_INT:-}


##============================================================================##
##------------------- Color Printing & Logging routines ----------------------##
##----------------------------------------------------------------------------##

# test if the terminal supports colors
if test -t 1; then
	_tput_colors=$(tput colors 2>/dev/null || true)
	if test -z "$_tput_colors"; then
		[[ "$TERM" != *"color"* ]] || TERM_COLORS=1
	elif test "$_tput_colors" -ge 8; then TERM_COLORS=1; fi
fi
export TERM_COLORS

# Associative map with log level colors & ANSI constants
declare -g -A SH_COLOR_PRINT_MAP=(
	['black']=30    ['red']=31       ['green']=32
	['yellow']=33   ['blue']=34      ['magenta']=35
	['cyan']=36     ['white']=37     ['default']=39
)
# supplementary text styles ("b-<color>" for bold etc, '*<color>' for bright)
for c in "${!SH_COLOR_PRINT_MAP[@]}"; do
	_cc="${SH_COLOR_PRINT_MAP[$c]}"
	SH_COLOR_PRINT_MAP+=( ["b-$c"]="1;$_cc" ["i-$c"]="3;$_cc" ["u-$c"]="4;$_cc"
		["x-$c"]="2;$_cc" ["*$c"]="$(( _cc + 60 ))" )
done

# Usage: sh_cecho [-ne] COLOR TEXT...
function sh_cecho() {
	local EARGS=() ESC=$'\e[' RST=$'\e[0m'
	while [[ $# -gt 1 ]]; do case "$1" in
		-*) EARGS+=("$1"); ;;
		*) break; ;;
	esac; shift; done
	local COLOR="${SH_COLOR_PRINT_MAP[$1]}"; shift
	[[ -n "$COLOR" ]] || return 1
	# handle color aliases:
	[[ ! -v "SH_COLOR_PRINT_MAP[$COLOR]" ]] || COLOR="${SH_COLOR_PRINT_MAP[$COLOR]}"
	COLOR="${ESC}${COLOR}m"
	[[ -n "$TERM_COLORS" ]] || { COLOR=''; ESC=''; RST=''; }
	# finally, compose the message
	echo "${EARGS[@]}" "${COLOR}$*${RST}";
}
# and some aliases:
function sh_color_echo() { sh_cecho "$@"; }

## ---- Logging functions ----
# aliases for syslog-compatible levels
declare -g -A SH_LOG_ALIASES=([error]=err [panic]=emerg)
# log colors (alias key from the same map)
SH_COLOR_PRINT_MAP+=([debug]="cyan" [info]="b-green" [err]="b-red" [emerg]="b-red")

# generic logging function
function sh_log() {
	local LEVEL="$1"; shift
	[[ ! -v "SH_LOG_ALIASES[$LEVEL]" ]] || LEVEL="${SH_LOG_ALIASES[$LEVEL]}"
	sh_hooks_run "sh_log_cb" "$LEVEL" "$*"
	sh_cecho "$LEVEL" "${SH_LOG_PREFIX:+"$SH_LOG_PREFIX: "}$*"
}

# only logs if the DEBUG variable is non-null
function sh_log_debug() { [[ -z "$DEBUG" ]] || sh_log "debug" "$@"; }
function sh_log_info() { sh_log "info" "$@"; }
function sh_log_error() { sh_log "err" "$@" >&2; }
function sh_log_panic() { sh_log "emerg" "$@" >&2; exit 1; }
# intenal debugging routine
function _sh_debug_int() {
	[[ -z "$SH_DEBUG_INT" ]] || sh_log "debug" "$@"
}

##============================================================================##
##-------------------------- String / output helpers -------------------------##
##----------------------------------------------------------------------------##

# Silences the output of a command (use in front)
function sh_silent() { "$@" >/dev/null 2>&1; }
if [[ -z "$SH_NO_ALIASES" ]]; then
	function @silent() { sh_silent "$@"; }
fi

# Removes whitespace from beginning/end of string
function sh_str_trim() {
	local VAR="$1"
	VAR="${VAR#"${VAR%%[![:space:]]*}"}"
	VAR="${VAR%"${VAR##*[![:space:]]}"}"
	echo -n "$VAR"
}

# Checks if a string contains a given substring
# str_contains NEEDLE HAYSTACK
function sh_str_contains() {
	[[ "$1" == *"$2"* ]]
}

# Interpolates multiple curly braced '{{VARIABLE}}'s within a given TEMPLATE.
# Uses env's syntax for VAR[=VALUE], first argument is the TEMPLATE.
function sh_interpolate_vars() {
	local TEMPLATE="$1"; shift
	for var in "$@"; do
		TEMPLATE="${TEMPLATE//"{{${var%%=*}}}"/"${var#*=}"}"
	done
	printf "%s" "$TEMPLATE"
}

# Checks if a separated path list ($1) contains an element ($2)
function sh_path_contains() {
	local SEP=${SEP:-':'}
	[[ "${SEP}$1${SEP}" == *"${SEP}$2${SEP}"* ]] || return 1
}
# Appends an element ($2) to a colon-separated path list ($1 - var. name)
function sh_path_append() {
	local -n _VAR="$1"
	_VAR="${_VAR:+"${_VAR}${SEP:-":"}"}$2"
}
# Prepends an element ($2) to a colon-separated path list ($1 - var. name)
function sh_path_prepend() {
	local -n _VAR="$1"
	_VAR="$2${_VAR:+"${SEP:-":"}${_VAR}"}"
}

##============================================================================##
##----------------------- Bash function/module helpers -----------------------##
##----------------------------------------------------------------------------##

# returns the path to the current script (the one invoking the function)
function sh_get_script_path() {
	cd -- "$(dirname -- "${BASH_SOURCE[1]}")" &>/dev/null && pwd
}

# checks whether a bash function was defined
function sh_is_function() {
	[[ -n "$1" && $(type -t "$1") == "function" ]]
}

# global variable for storing named function hooks
declare -g -A _SH_FUNC_HOOKS=()

# Import path used by @import utility (colon-separated, like PATH env. var)
# Contains base.sh's directory by default
SH_MOD_PATH="$(sh_get_script_path)"

# cache the already imported modules (abs path) to prevent re-importing
declare -g -A _SH_MODULES_IMPORTED=()

# Sources a '.sh' module (tries all paths in SH_MOD_PATH)
# If SH_NO_ALIASES is not 1, then `@import` is defined as an alias
# Example: @import 'mymodule' (.sh extension is added automatically)
function sh_import() {
	local __MOD_NAME="" __MOD_PATH="" _PARENT="" _OPTIONAL=""
	# split module path into array
	local -a __MOD_SEARCH_PATH=()
	while [[ $# -gt 1 ]]; do case "$1" in
		--opt|--optional) _OPTIONAL=1 ;;
		-p|--parent) _PARENT=1 ;;
		-*) sh_log_error "@import: invalid option: $1"; return 1 ;;
		*) break; ;;
	esac; shift; done
	__MOD_NAME="${*%.sh}"
	if [[ -n "$_PARENT" ]]; then
		if [[ "$(declare -p __MOD_PARENT_PATH 2>/dev/null)" != 'declare'*'-a'* ]]; then
			sh_log_error "@import: parent module unavailable in current scope!"; return 1
		fi
		__MOD_SEARCH_PATH=("${__MOD_PARENT_PATH[@]}")
	else
		IFS=':' read -r -a __MOD_SEARCH_PATH <<< "${SH_MOD_PATH}"
	fi

	# determine the absolute path of the requested module
	if [[ "$*" == /* ]]; then  # module already has absolute path?
		__MOD_PATH="$*"
	else
		for i in "${!__MOD_SEARCH_PATH[@]}"; do
			[[ -n "${__MOD_SEARCH_PATH[$i]}" ]] || continue  # ignore empty entries
			if [[ -f "${__MOD_SEARCH_PATH[$i]}/$__MOD_NAME.sh" ]]; then
				__MOD_PATH="${__MOD_SEARCH_PATH[$i]}/$__MOD_NAME.sh"
				# provide parent path for modules wishing to import `--parent`s
				local -a __MOD_PARENT_PATH=("${__MOD_SEARCH_PATH[@]:$(( i + 1 ))}")
				break
			fi
		done
	fi
	# prevent double imports using global associative array
	if [[ -z "$__MOD_PATH" || ! -f "$__MOD_PATH" ]]; then
		[[ -z "$_OPTIONAL" ]] || return 0
		sh_log_error "Module not found: '$__MOD_NAME.sh'"
		_sh_debug_int "Module path: '$SH_MOD_PATH'"
		return 2
	fi
	if [[ -v _SH_MODULES_IMPORTED["$__MOD_PATH"] ]]; then
		return 0  # module already loaded!
	fi
	_SH_MODULES_IMPORTED["$__MOD_PATH"]=1
	# cleanup temp. vars
	unset i _OPTIONAL _PARENT __MOD_SEARCH_PATH

	# finally: source the module!
	source "$__MOD_PATH" || return 3
	_sh_debug_int "mod: $__MOD_NAME: loaded!"
}
if [[ -z "$SH_NO_ALIASES" ]]; then  # create @import alias
	function @import() { sh_import "$@"; }
fi

# calls all hooks registered for a named event/function
# usage: hooks_run EVENT_NAME
# The callback is invoked with the hook name as its first argument ($1), then 
# the `sh_hooks_run`-given parameters are passed in order (as $2, $3...).
function sh_hooks_run() {
	[[ -v _SH_FUNC_HOOKS["$1"] ]] || return 0
	IFS=, read -ra hooks <<< "${_SH_FUNC_HOOKS["$1"]}"
	for fun_ in "${hooks[@]}"; do
		"$fun_" "$@"
	done
}

# appends/prepends a hook function to a given event list
# usage: hooks_add EVENT_NAME [-]FUNCTION_NAME
# if the function name is prefixed by '-', the hook is prepended
function sh_hooks_add() {
	[[ -v _SH_FUNC_HOOKS["$1"] ]] || _SH_FUNC_HOOKS["$1"]=""
	if ! SEP=, sh_path_contains "${_SH_FUNC_HOOKS["$1"]}" "$2"; then
		if [[ "$2" == '-'* ]]; then
			SEP=, sh_path_prepend "_SH_FUNC_HOOKS[$1]" "${2:1}"
		else
			SEP=, sh_path_append "_SH_FUNC_HOOKS[$1]" "$2"
		fi
	fi
}

