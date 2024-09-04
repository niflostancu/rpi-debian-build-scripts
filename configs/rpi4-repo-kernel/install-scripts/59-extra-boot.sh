#!/bin/bash
# post-bootloader install hook

# re-generate initramfs
update-initramfs -u -k all

