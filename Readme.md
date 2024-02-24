# RaspberryPi Debian-based rootfs build scripts

This project contains several scripts for building a minimalistic rootfs,
kernel and boot files, primarily for personal use with a RPI4-based NAS (Network
Attached Storage), but fairly customizable (using configuration modules).

Features:

- a `qemu-user` + `binfmt` + `debootstrap` approach for cross-bootstrapping rootfs;
- scripts for easily chrooting inside the rootfs container (using `systemd-nspawn`);
- custom kernel building script (using cross-compiler);
- modular approach for running a series of provisioning scripts inside the
  rootfs to fully configure the Debian installation;
- configuration for a LUKS-based setup with dropbear-initramfs for remote
  unlocking (via ssh);
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
Also, kernel compile dependencies must be present (a provisioning script is
included for Vagrant ;) )!

## Building

The kernel and the rootfs are built separately, though the final stages
of the provisioning scripts require a kernel `.deb` package to be present.

First, read (but don't modify!) through `config.default.sh` for a list of the
available variables. If you want to customize them, simply create `config.sh`
and set your desired options (it is gitignored).

Additionally, you can use a predefined configuration overlay or build your own!
Check out the [`configs/`](./configs/) directory, then set / export the
`CUSTOM_CONFIG` environment variable with the name of the configuration
/ board's directory, e.g.:

```sh
export CUSTOM_CONFIG="interceptor-6.x"
```

### Kernel

To manually compile the kernel, use a Debian-based system with kernel
dependencies installed.
For this specific purpose, a Vagrantfile is also supplied (configured to spawn
a Debian-based VM).

Then, simply run the script: `./build-kernel.sh`!

After building the kernel, the `*.deb`s are automatically copied to the
`dist/kernel-<config-ver>` subdirectory.

The `build-rootfs.sh` script will look there during the install phase (see
[57-kernel.sh](rootfs-install/scripts/57-kernel.sh)).

### RootFS

For building the rootfs, the `build-rootfs.sh` script will run all bootstrapping
and provisioning stages.
The installation scripts can be re-run at any time by invoking the same script
(scripts were designed for idempotence, i.e. not doing the same thing again).

### Image

Finally, use the `build-image.sh` script should obtain a raw bootable image
(with two partitions: a FAT32 with RPI boot files, and the ext4 rootfs).

You might wish to customize your boot media, see the next section for details.

### U-Boot (optional)

If you wish to build a custom u-boot
[BL31](https://trustedfirmware-a.readthedocs.io/en/latest/design/firmware-design.html#cold-boot)
loader for your RaspberryPi, start by checking out the `build-uboot.sh` script!

Note: you must manually modify `config.txt` to enable it, for now (example
configs are WIP)!

## Advanced usage

For advanced use cases, read below:

### Manually deploying to internal RaspberryPi 4 boot media

For example, if you want to install on Compute Module's internal eMMC or an
attached SSD drive and you don't want to move it to an external PC:

0. Make sure you understand the [RPI4 boot
  process](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-4-boot-flow).
  Also check if your current bootloader version supports the required features
  (i.e., boot from USB), upgrade if necessary.

1. First, archive the generated rootfs:
  ```sh
  tar czf dist/rootfs.tar.gz -C "$ROOTFS_DEST" .
  ```

  Note: the following next steps may be executed on whatever storage media you
  want to run it from (e.g., internal eMMC / SD card or even PCIe / SATA SSDs).

2. Boot the Raspberry PI (or similar embedded device) into a live distro (e.g.,
  from USB). Arch Linux works best for this purpose ;) Alternatively,
  a separate Debian-based image built using `build-image.sh` will also work,
  though you will need to manually install some packages (e.g., partition
  manager, FS utils, `arch-install-scripts`).

3. Partition your disk(s) to have at least a RaspberryPI FAT32 boot partition
  (usually, 256MB is enough) and an empty `ext4` partition to install the rootfs
  to. Note: you can even use different disks ;) !

  Note: the stock RPI bootloader cannot boot from an external SSD drive,
  but you can put the boot partition inside the eMMC memory and the root partition
  on the SSD (and have this `root=` path configured on the kernel's cmdline).

4. Mount the root device and extract the rootfs archive on your desired partition:
  ```sh
  # assumes you have the ext4 partition mounted in /mnt:
  tar xf "rootfs.tar.gz" -C /mnt
  ```

  Optionally, chroot inside the newly installed rootfs and tweak your settings
  (don't forget to change the user's password / add ssh authorized_keys).

5. Now, finally, the boot partition: it's recommended to mount it into a separate
  path than `/boot`, e.g. `/boot/firmware`:

  ```sh
  mkdir -p /boot/firmware
  mount /dev/mmcblk0p1 /boot/firmware
  # note: the Interceptor board uses mmcblk1*! better check using `lsblk`.
  ```

  The included `initramfs` script generates a `boot.img` disk image with the
  kernel, initramfs and other config/firmware files required by the RPI
  bootloader (you can disable this using the `RPI_SKIP_BOOT_RAMDISK` config
  variable).

  You can simply copy it to RPI's boot partition and use a simple config.txt
  telling it to [load the ramdisk](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#boot_ramdisk):
  ```sh
  # note: replace this path if you are inside chroot
  cp -f /mnt/boot/boot.img /boot/firmware/boot.img
  echo "boot_ramdisk=1" > /boot/firmware/config.txt
  ```

  Using this, you can also support boot failover configurations (WIP/TODO)!

### Configuring LUKS initramfs for password input

Additional steps must be taken for a LUKS-based setup (on the live RPI distro):

- Before extracting the archive onto the root filesystem, make sure to use
  a LUKS-formatted partition (optionally with LVM; read the [Arch
  Wiki](https://wiki.archlinux.org/title/dm-crypt/Device_encryption));

  Make sure to open & mount the newly created partition to `/mnt`, e.g.:
  ```sh
  # assuming you labeled the GPT partition (hint: use gdisk):
  cryptsetup luksOpen /dev/disk/by-partlabel/RPIOSRoot cryptroot
  mount /dev/mapper/cryptroot /mnt
  ```

- chroot into the partition; hint: use the `arch-chroot` script (also available
  on debian after installing the `arch-install-scripts`) which makes this easy:

  ```sh
  arch-chroot /mnt
  ```

- Create a `/etc/crypttab` containing at least one entry for the `cryptroot`
  target (or whatever name you used when opening the LUKS device):

  ```
  # <target> <source device>                 <key file>  <options>
  cryptroot  /dev/disk/by-partlabel/RPIOSRoot  none        luks,discard
  ```

- If using the included `initramfs` hooks, change the `/etc/initramfs/rpi-*`
  files on the rootfs and enter the required RPI config + kernel cmdline parameters.

- Finally, run `update-initramfs -u` to re-generate the initial ramdisk and copy
  the `boot.img` to the boot partition (as in Step. 5).

## Frequently asked questions / Workarounds

### Temporary failure in name resolution

Unfortunately, `systemd-nspawn` overwrites the `/etc/resolv.conf` file. If you
want to use `systemd-resolved` as DNS resolver, [take a look
here](https://wiki.archlinux.org/title/Systemd-resolved) (Arch Wiki FTW!); TLDR:

```sh
# on a booted (i.e., non-chroot) system:
ln -rsf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

