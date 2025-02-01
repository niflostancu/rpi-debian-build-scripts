#!/bin/bash

set -e

if [ $# -eq 0 ]; then
	set -- bash
fi

"$@"

