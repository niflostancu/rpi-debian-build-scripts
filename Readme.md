# RaspberryPi Debian (arm64) rootfs build scripts for NAS

This project contains several scripts for building a minimalistic rootfs,
kernel and boot files for use with a RPI4-based NAS (Network Attached Storage).

Features:

- a `qemu-user` + `binfmt` + `debootstrap` approach for cross-bootstrapping rootfs;
- script for easily chrooting inside the rootfs container (using `systemd-nspawn`);
- custom kernel building script (using cross-compiler);
- modular approach for running a series of provisioning scripts inside the
  rootfs to fully configure the Debian installation;
- utility bash libraries for colorful logging / debugging / package management;
- vagrant provisioning file for non-Debian hosts;

Although it contains settings tailored for a specific RPI CM4 carrier board (the
[Axzez Interceptor](https://www.axzez.com/axzez-circuit-boards)), it was
designed to be easily configurable and should also serve as a starting point for
similar projects (e.g., building embedded distributions).

## Prerequisites

Host system requirements for rootfs bootstrapping:

- A modern Linux distro with Systemd (for `systemd-nspawn`);
- The [`debootstrap`](https://wiki.debian.org/Debootstrap) utility;
- Binaries for `qemu-user-static` and `binfmt` handlers properly configured for
  the desired architecture (i.e., aarch64)

For building the kernel, either a Debian-based host distro is required (for .deb
generation) or a working [Vagrant](https://www.vagrantup.com/) install (a
provisioning script is provided).
Also, kernel compile dependencies must be present!

## Building

The kernel and the rootfs are built separately, though the final stages
of the provisioning scripts require a kernel `.deb` package to be present.

First, copy `config.sample.sh` as `config.sh` and enter the desired values.

To compile the kernel, use a Debian-based system with kernel dependencies
installed, then: `./build-kernel.sh`. Manually copy the generated `.deb` files
to the `dist/` directory (create it if it doesn't exist).
For this specific purpose, a Vagrantfile is also supplied (configured to spawn
a Debian-based VM).

For building the rootfs, the `build-rootfs.sh` script will run all bootstrapping
and provisioning stages.
The provisioning stages can be re-run at any time by invoking the same script
(scripts were designed for idempotence, aka not doing the same thing again).

## Deploying to RaspberryPi boot media

0. Make sure you understand the [RPI4 boot
  process](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-4-boot-flow).
  Also check if your current bootloader version supports the required features,
  upgrade if necessary.

1. First, archive the generated rootfs:
  ```sh
  tar czf dist/rootfs.tar.gz -C "$ROOTFS_DEST" .
  ```

  Note: the following next steps may be executed on whatever storage media you
  want to run it from (e.g., internal eMMC / SD card or even PCIe / SATA SSDs).

2. Boot the Raspberry PI (or similar embedded device) into a live distro (e.g.,
  from USB). Arch Linux works best for this purpose ;)

3. Partition your disk(s) to have at least a RaspberryPI FAT32 boot partition
  (usually, 256MB is enough) and an empty `ext4` partition to install the rootfs
  to. Note: you can even use different disks ;) !

  Note: the stock RPI bootloader cannot boot from an external SSD drive,
  but you can put the boot partition inside the eMMC memory and the root partition
  on the SSD (and have this path configured at the kernel command line).

4. Mount the root device and extract the rootfs archive on your desired partition:
  ```sh
  # assumes you have the ext4 partition mounted in /mnt:
  tar xf "rootfs.tar.gz" -C /mnt
  ```

5. Now, finally, the boot partition: it's recommended to mount it into a separate
   path than `/boot`, e.g. `/boot/rpi`.

  The included initramfs script has already generated a `boot.img` disk image
  with the kernel, initramfs and other config/firmware files required by the RPI
  bootloader.

  You can simply copy it to RPI's boot partition and use a simple config.txt
  telling it to [load the ramdisk](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#boot_ramdisk):
  ```ini
  boot_ramdisk=1
  ```

  Using this, you can also support boot failover configurations (TODO)!

