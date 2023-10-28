#!/bin/bash
# Cleans up provisioning files

apt-get --purge -y autoremove
apt-get -y clean

rm -rf /root/rpi-provisioning/

