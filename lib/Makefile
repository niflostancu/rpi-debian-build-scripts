# Makefile to maintain / upgrade shell scripts library used for development
# purposes (alternative to git modules management).
#
# Simply invoke dev-upgrade target.

# vim: set filetype=make:

# sh-lib fetch parameters
SH_LIB_VERSION = main
SH_LIB_FETCH_URL = https://raw.githubusercontent.com/niflostancu/sh-lib/refs/heads/{VERSION}
# list of space-separated libraries to fetch / upgrade from sh-lib
SH_LIB_FILES = base.sh linux.sh

# fetch.sh download URL
FETCH_SH_URL = "https://raw.githubusercontent.com/niflostancu/release-fetch-script/master/fetch.sh"

help:
	@echo "Available targets:"
	@echo "	 dev-upgrade 		Downloads / upgrades all declared dependencies"
	@echo "	 fetch.sh 			Ensures that the fetch.sh script is present (auto dep)"
	@echo "	 fetch.sh-upgrade 	Upgrades fetch.sh library"

.PHONY: help dev-upgrade fetch.sh-upgrade

dev-upgrade: $(SH_LIB_FILES)
$(SH_LIB_FILES): fetch.sh FORCE
	./fetch.sh --set-version="$(SH_LIB_VERSION)" --print-hash --download="$@" \
		"$(SH_LIB_FETCH_URL)/$@"

# downloads the fetch.sh utility
fetch.sh:
	wget -O fetch.sh "$(FETCH_SH_URL)"
	chmod +x fetch.sh

# Upgrades fetch.sh
fetch.sh-upgrade: fetch.sh
	./fetch.sh --self-update

# remove all downloaded dependencies
distclean:
	rm -f fetch.sh $(SH_LIB_FILES)

.PHONY: FORCE 
FORCE:

