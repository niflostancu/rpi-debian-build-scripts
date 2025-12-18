#!/bin/bash
# Cleans up tmp, packages & provisioning files

(
	set +e
	apt-get --purge -y autoremove
	apt-get -y clean
	rm -f /etc/ssh/ssh_host_*
	mv /etc/machine-id{,.old}
	rm -f /var/lib/systemd/random-seed
	rm -f /etc/udev/rules.d/70*
	rm -rf /root/rpi-provisioning/
	rm -rf /tmp/*
	rm -rf /var/tmp/* /var/cache/*
)

