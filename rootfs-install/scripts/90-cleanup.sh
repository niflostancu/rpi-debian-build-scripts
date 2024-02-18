#!/bin/bash
# Cleans up tmp, packages & provisioning files

apt-get --purge -y autoremove
apt-get -y clean

rm -rf /root/rpi-provisioning/

