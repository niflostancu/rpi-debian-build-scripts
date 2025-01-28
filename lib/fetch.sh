#!/bin/bash
# Fetch - automatically retrieve the latest version / URL a repository release. 
# https://github.com/niflostancu/release-fetch-script
# v0.3.1
#
# Prerequisites: bash curl jq
#
# You can use it for the following services:
#  - github.com: released assets (tagged versions);
#  - raw.githubusercontent.com resources (version placeholders for refs/heads/tags);
#  - hub.docker.com: for docker tags (specify jq filtering using # in URL);

set -e
SCRIPT_SRC=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}" )" &>/dev/null && pwd -P)

# Use for debugging shell calls from make
_debug() {
	[[ -n "$DEBUG" && "$DEBUG" -gt 0 ]] || return 0
	if [[ "$1" =~ ^-[0-9]$ ]]; then [[ $DEBUG -ge ${1#-} ]] || return 0; shift; fi
	echo "DEBUG: fetch.sh: $*" >&2;
}
_fatal() { echo "$@" >&2; exit 2; }

print_help() {
	echo -e "Usage: \`fetch.sh [OPTIONS] URL\`"
	echo -e "Fetches repository tag/asset/image version data and/or files.\n"
	echo -e "The URL specifies the path to the repository & resource / asset to fetch."
	echo -e "You can specify custom service-specific filters inside the URI fragment (e.g., '#prefix=v2.')"
	echo -e "You may also use special placeholders (e.g., '{VERSION}', '{HASH}') in some of its components."
	echo -e "A service may have limited supported functions (e.g., no download / hash). \n"
	echo -e "Options:"
	echo -e "	 --debug|-d: enable debug messages"
	echo -e "	 --version: prints the local fetch script's version string"
	echo -e "	 --latest: always fetch the latest version (overrides cache)"
	echo -e "	 --set-version=VERSION: fetch a specific version / commit string"
	echo -e "	 --set-*[=VALUE]: set configuration variables (alt. to fragment vars)"
	echo -e "	 --cache-file=FILE: file to cache the retrieved metadata vars"
	echo -e "	 --header|-H EXTRA_HEADER: specify extra headers to curl (for version fetching & download)"
	echo -e "	 --print-version: prints the version number (the default, if no other --print* present)"
	echo -e "	 --print-hash: prints the commit / asset's digest (multiple --print's are done in given order)"
	echo -e "	 --print-url: prints the download URL"
	echo -e "	 --download=DEST_NAME: uses curl to automatically download the asset to DEST_NAME"
	echo -e "	 --self-update: self updates this script (fetches the latest version and replaces self with it)"
	echo && exit 1
}

# runtime metadata vars + stores
declare -g URL="" SERVICE="" CACHE_FILE="" FETCH_LATEST="" DOWNLOAD_DEST="" SELF_UPDATE=""
declare -g -a OUTPUT=()
declare -g -a CURL_ARGS=(-L)
declare -g -A USER_VARS=() META=() CACHE=()
# available vars & dependencies
declare -g -a METADATA_VARS=(version hash url)
declare -g -A METADATA_DEPS=([hash]="version" [url]="")  # URL is dynamic

# Script setup
shopt -s expand_aliases
_debug "$*"; [[ "$#" -gt 0 ]] || print_help
_debug -2 "DEBUG: $DEBUG"
alias _parse_optval='if [[ "$1" == *"="* ]]; then _OPT_VAL="${1#*=}"; else _OPT_VAL="$2"; shift; fi'

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
		--help|-h) print_help; ;;
		--debug|-d) DEBUG=1; ;;
		--version) SCRIPT_VERSION="$(cat "$0" | grep -E '# v[0-9.]+.*' | head -1)"; echo "${SCRIPT_VERSION##'# '}"; exit 0; ;;
		--latest) USER_VARS["version"]="__fetch"; ;;
		--set-*) [[ "$1" =~ ^--set-([^=]+)(=.*)?$ ]] || _fatal "Invalid option: $1"
			_parse_optval && USER_VARS["${BASH_REMATCH[1]}"]="$_OPT_VAL"; ;;
		--cache-file|--cache-file=*|--version-file|--version-file=*)
			_parse_optval && CACHE_FILE="$_OPT_VAL"; ;;
		--header|--header=*|-H) _parse_optval && CURL_ARGS+=(-H "$_OPT_VAL"); ;;
		--get-ver|--print-version|--print-ver) OUTPUT+=(version); ;;
		--get-hash|--print-hash) OUTPUT+=(hash); ;;
		--get-url|--print-url) OUTPUT+=(url); ;;
		--download|--download=*) _parse_optval && DOWNLOAD_DEST=$_OPT_VAL; ;;
		--self-update) SELF_UPDATE=1 ;;
		-*) _fatal "Invalid argument: $1" ;;
		*) break ;;
	esac
	shift
done
# quick prerequisites check
for program in jq curl sed; do
	type "$program" >/dev/null || \
		_fatal "$program not found (not installed or not in PATH)!"
done

# Supported services domains (used for URL detection)
declare -A SERVICES=(
	["github.com"]="github"
	["raw.githubusercontent.com"]="github_raw"
	["hub.docker.com"]="docker_hub"
)
# Parses an URL fragment and returns each pair on a newline
# (easy to iterate using `read -r line`)
# Accepted format: #key1=value;key2=value...
function parse_url_fragment() {
	local pair= PAIRS=()
	if [[ "$1" =~ ^[^#]*#(.+)$ ]]; then
		IFS=';' read -ra PAIRS <<< "${BASH_REMATCH[1]}"
		for pair in "${PAIRS[@]}"; do
			echo "$pair"
		done
	fi || true
}

# Interpolates metadata '{VARIABLE}'s in a template string (usually, URLs)
function replace_metadata() {
	local rs="$1" var=
	for var in "${METADATA_VARS[@]}"; do
		# replace uppercased ${var} with its actual value
		rs="${rs//{${var^^}\}/${META["$var"]}}"
	done
	echo -n "$rs"
}

# Calls curl with default arguments.
curl:fetch() { _debug -2 "curl ${CURL_ARGS[*]} $*";
	curl --fail --show-error --silent "${CURL_ARGS[@]}" "$@"; }
# JQ utilities for building filters
jq:filter:prefix() { [[ -z "$1" ]] || echo "map(select(${2:+$2"|"}tostring|startswith(\"$1\")))"; }
jq:filter:suffix() { [[ -z "$1" ]] || echo "map(select(${2:+$2"|"}tostring|endswith(\"$1\")))"; }
jq:sortby() { local acc=;
	for v in "$@"; do [[ -z "$v" ]] || acc+="${acc:+", "}$v"; done
	echo "${acc:+sort_by($acc)}"; }
jq:join_pipe() { local -n ref="$1"; shift; for v in "$@"; do [[ -z "$v" ]] || ref="${ref:+"$ref | "}$v"; done; }
jq:run() { _debug -2 "jq -r $*"; jq -r "$*"; }

# Parses a GitHub URL
# Accepted formats:
# - https://github.com/{org}/{repo}(/releases/download/{VERSION}/...)?
# - https://github.com/{org}/{repo}(/archive/refs/tags/{VERSION}.(zip|tar.gz))?
# - https://raw.githubusercontent.com/{org}/{repo}/refs/tags/{VERSION}/...
# - https://raw.githubusercontent.com/{org}/{repo}/refs/heads/{BRANCH}/...
function service:github:parse_url() {
	_GH_FULLREPO=""; _GH_URL_REST=""; _GH_REF_TYPE=""
	if [[ "$1" =~ ^https?://[^/]+/([^/]+/[^/]+)([/#].*)?$ ]]; then
		_GH_FULLREPO="${BASH_REMATCH[1]}"
		_GH_URL_REST="${BASH_REMATCH[2]#/}"
		if [[ "$_GH_URL_REST" =~ ^(archive/)?refs?/(heads|tags)([/#].*)?$ ]]; then
			_GH_REF_TYPE="${BASH_REMATCH[2]}"
		fi
	else
		_fatal "Unable to parse URL: $1"
	fi
}
function service:github:fetch_metadata() {
	local FIELD="$1" line="" JQ_FILTERS=""
	local API_URL="https://api.github.com/repos/$_GH_FULLREPO" 
	local PREFIX="${USER_VARS[prefix]}" SUFFIX="${USER_VARS[suffix]}"
	local PRERELEASE=${USER_VARS[prerelease]}
	while IFS= read -r line; do
		case $line in
			prefix=*|pfx=*) PREFIX=${line#*=}; ;;
			suffix=*|sfx=*) SUFFIX=${line#*=}; ;;
			prerelease|pre) PRERELEASE=1; ;;
		esac
	done < <( parse_url_fragment "$_GH_URL_REST" )
	if [[ "$FIELD" == "version" ]]; then
		API_URL+="/releases"
		[[ -n "$PRERELEASE" ]] || jq:join_pipe JQ_FILTERS 'map(select(.prerelease==false))'
		jq:join_pipe JQ_FILTERS '[.[].tag_name]'
		jq:join_pipe JQ_FILTERS "$(jq:filter:prefix "$PREFIX")" "$(jq:filter:suffix "$SUFFIX")"
		jq:join_pipe JQ_FILTERS 'first'
		curl:fetch "$API_URL" | jq:run "$JQ_FILTERS"
	elif [[ "$FIELD" == "hash" ]]; then
		# fetch commit SHA from the GH API
		API_URL+="/git/refs/${_GH_REF_TYPE:-tags}/${META["version"]}" 
		curl:fetch "$API_URL" | jq:run ".object.sha"
	else _fatal "Metadata field supported: $FIELD"; fi
}
function service:github:get_download_url() { replace_metadata "$1"; }

# Github Raw URL service alias (see github above)
function service:github_raw:parse_url() { service:github:parse_url "$@"; }
function service:github_raw:fetch_metadata() { service:github:fetch_metadata "$@"; }
function service:github_raw:get_download_url() { replace_metadata "$1"; }

# Docker Hub latest tag query (via API v2)
# Accepted formats:
# - https://hub.docker.com/_/{repo}/#filter={VERSION}
# - https://hub.docker.com/(r|repository/docker)/{org}/{repo}/#filter={VERSION}
function service:docker_hub:parse_url() {
	# reset internal cache vars
	_DH_NAMESPACE=""; _DH_REPONAME=""; _DH_URL_REST=""
	if [[ "$1" =~ ^https?://[^/]+/_/([^/#]+)([/#].*)??$ ]]; then
		# official library
		_DH_NAMESPACE=library
		_DH_REPONAME="${BASH_REMATCH[1]}"
		_DH_URL_REST="${BASH_REMATCH[2]#/}"
	elif [[ "$1" =~ ^https?://[^/]+/(r|repository/docker)/([^#/]+)/([^#/]+)([/#].*)?$ ]]; then
		# named project
		_DH_NAMESPACE="${BASH_REMATCH[2]}"
		_DH_REPONAME="${BASH_REMATCH[3]}"
		_DH_URL_REST="${BASH_REMATCH[4]#/}"
	else
		_fatal "Unable to parse URL: $1"
	fi
}
function service:docker_hub:fetch_metadata() {
	local FIELD="$1" line= JQ_FILTERS=
	local API_URL="https://hub.docker.com/v2/namespaces/$_DH_NAMESPACE/repositories/$_DH_REPONAME/tags"
	local LONGEST="${USER_VARS[longest]}" PAGE_SIZE="${USER_VARS[page_size]}"
	local PREFIX="${USER_VARS[prefix]}" SUFFIX="${USER_VARS[suffix]}"
	while IFS= read -r line; do
		case "$line" in
			prefix=*|pfx=*) PREFIX=${line#*=}; ;;
			suffix=*|sfx=*) SUFFIX=${line#*=}; ;;
			page_size=*|max_count=*) PAGE_SIZE=${line#*=}; ;;
			longest|long) LONGEST=1; ;;
		esac
	done < <( parse_url_fragment "$_DH_URL_REST" )
	if [[ "$FIELD" == "version" ]]; then
		API_URL+="?page_size=${PAGE_SIZE:-100}"
		jq:join_pipe JQ_FILTERS '.results' 'map(select(.name != "latest"))' \
			"$(jq:filter:prefix "$PREFIX" '.name')" "$(jq:filter:suffix "$SUFFIX" '.name')"
		# sort by date desc, longest prefix first (optional)
		local JQ_SORTBY="$(jq:sortby '.last_updated' "${LONGEST:+"(100-(.name|length))"}")"
		jq:join_pipe JQ_FILTERS "$JQ_SORTBY" "reverse" "first" ".name"
		curl:fetch "$API_URL" | jq:run "$JQ_FILTERS"
	elif [[ "$FIELD" == "hash" ]]; then
		API_URL+="/${META["version"]}"
		# remove hash prefix from the digest value (e.g., 'sha256:...')
		jq:join_pipe JQ_FILTERS '.digest' 'sub(".*:"; "")'
		curl:fetch "$API_URL" | jq:run "$JQ_FILTERS"
	else _fatal "Metadata field supported: $FIELD"; fi
}
function service:docker_hub:get_download_url() {
	_fatal "Docker Hub download not supported!"
}

# Self-upgrade function. Called when --self-update is set.
# (for out-of-tree usage of the fetch.sh script)
function fetch_self_update() {
	URL="https://raw.githubusercontent.com/niflostancu/release-fetch-script/{VERSION}/fetch.sh"
	DOWNLOAD_DEST="$0"
	[[ -n "${USER_VARS[version]}" ]] || USER_VARS["version"]=__fetch
}

# Requests / fetches missing metadata variables ($@) to be available in the
# META[@] associative array (if not already).
function request_metadata() {
	local var= dep_for=
	if [[ "$1" == "--for="* ]]; then _parse_optval && dep_for="$_OPT_VAL"; shift; fi
	for var in "$@"; do
		[[ -z "${META["$var"]}" ]] || continue
		# fetch dependencies first
		[[ -z "${METADATA_DEPS[$var]}" ]] || request_metadata --for="$var" ${METADATA_DEPS[$var]}
		local value=
		if [[ -n "${USER_VARS["$var"]}" ]]; then  # invalidate dependency source
			[[ -z "$dep_for" || -n "${USER_VARS[$dep_for]}" ]] || USER_VARS["$dep_for"]="__fetch"
		fi
		if [[ "$var" == "url" ]]; then # URL is a special variable
			value="$(service:$SERVICE:get_download_url "$URL")"
		elif [[ "${USER_VARS[$var]}" == "__fetch" ]]; then
			value="$(service:$SERVICE:fetch_metadata "$var")";
		elif [[ -n "${USER_VARS["$var"]}" ]]; then value="${USER_VARS[$var]}"
		elif [[ -n "${CACHE["$var"]}" ]]; then value="${CACHE[$var]}"
		else value="$(service:$SERVICE:fetch_metadata "$var")"; fi
		if [[ -z "$value" ]]; then _fatal "Could not determine $var"; fi
		META["$var"]="$value"
	done
}

# tries to read the required metadata from cache;
# results are stored in the global CACHE associative array!
function read_cached_metadata() {
	[[ -f "$1" ]] || return 1
	local idx=0 line=
	while IFS="" read -r line; do
		local var="${METADATA_VARS[$idx]}"
		[[ -n "$var" ]] || break
		# remove trailing whitespace
		line="${line%"${line##*[![:space:]]}"}"
		CACHE["$var"]=$line
		idx=$(( $idx + 1 ))
	done <"$1"
}

# caches the retrieved metadata to a file (if they are different from CACHE)
function cache_metadata() {
	local CACHE_FILE="$1"
	_debug -2 "cache: file: '$CACHE_FILE'"
	local NEW_CONTENTS= var=
	for var in "${METADATA_VARS[@]}"; do
		NEW_CONTENTS+="${META["$var"]}"$'\n'
	done
	# prevent unneeded modification (e.g., to keep makefiles from re-building)
	local CUR_CONTENTS=
	[[ ! -f "$CACHE_FILE" ]] || CUR_CONTENTS=$(cat "$CACHE_FILE")
	if [[ "$CUR_CONTENTS" != "$NEW_CONTENTS" ]]; then
		mkdir -p "$(dirname "$CACHE_FILE")"
		echo -n "$NEW_CONTENTS" > "$CACHE_FILE"
		_debug "cache: saved metadata to file!"
	else
		_debug -2 "cache: has identical content"
	fi
}

# a little post-args processing for default value inference
URL="$1"
if [[ -n "$SELF_UPDATE" ]]; then fetch_self_update; fi
if [[ ${#OUTPUT[@]} -le 0 ]]; then OUTPUT+=(version); fi

# begin with URL parsing and service auto-detection
# (TODO: provide option to override)
SERVICE=$(echo "$URL" | sed -e 's/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/')
if [[ ! -v SERVICES["$SERVICE"] ]]; then
	_fatal "Service $SERVICE not supported!" >&2
fi
SERVICE=${SERVICES["$SERVICE"]}

# call service-specific URL parser hook
service:$SERVICE:parse_url "$URL"
[[ -z "$CACHE_FILE" ]] || read_cached_metadata "$CACHE_FILE" || \
	_debug "cache: not found"
# fetch the required metadata variables (plus dependencies)
declare -a REQUEST_VARS=()
for _var in "${METADATA_VARS[@]}"; do
	[[ "$URL" == *"{${_var^^}}"* ]] && METADATA_DEPS[url]+="$_var " || true
	[[ " ${OUTPUT[*]} " =~ " $_var " ]] && REQUEST_VARS+=("$_var") || true
done
[[ -z "$DOWNLOAD_DEST" ]] || REQUEST_VARS+=(url)
request_metadata "${REQUEST_VARS[@]}"

# print the requested output metadata
_debug "output: ${OUTPUT[*]}"
for out_field in "${OUTPUT[@]}"; do
	[[ " ${METADATA_VARS[*]} " =~ " $out_field " ]] || \
		_fatal "Unknown output field: $out_field"
	echo "${META["$out_field"]}"
done

# finally, download file(s), if requested
if [[ -n "$DOWNLOAD_DEST" ]]; then
	DOWNLOAD_URL="${META["url"]}"
	DOWNLOAD_DEST=$(replace_metadata "$DOWNLOAD_DEST")
	_debug "downloading $DOWNLOAD_URL to '$DOWNLOAD_DEST'"
	mkdir -p "$(dirname "$DOWNLOAD_DEST")"
	_debug -2 "download: curl:${CURL_ARGS[@]} -L -o $DOWNLOAD_DEST $DOWNLOAD_URL"
	curl --fail --show-error --silent "${CURL_ARGS[@]}" -L -o "$DOWNLOAD_DEST" "$DOWNLOAD_URL"
	echo "$DOWNLOAD_DEST"
fi

# if everything went well this far, save the metadata file
[[ -z "$CACHE_FILE" ]] || cache_metadata "$CACHE_FILE"

