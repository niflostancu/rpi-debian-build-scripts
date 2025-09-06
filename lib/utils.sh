#!/bin/bash

function version_greater_eq() {
	local currentver="$1"
	local requiredver="$2"
	[ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]
}

