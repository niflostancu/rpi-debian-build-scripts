# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # we need a Debian-like distro for kernel .deb generation
  config.vm.box = "debian/bullseye64"

  # Disable automatic box update checking
  # config.vm.box_check_update = false

  # use rsync for one-way syncing of scripts
  config.vm.synced_folder ".", "/vagrant", type: "rsync",
    rsync__auto: true,
    rsync__exclude: [".git/", ".vagrant/"]

  # We need sufficient resources for the kernel cross-compilation tasks
  config.vm.provider "virtualbox" do |vbox|
    vbox.cpus = 4
    vbox.memory = "4096"
  end

  config.vm.provider "libvirt" do |libvirt|
    libvirt.cpus = 4
    libvirt.memory = "4096"
  end

  # Run provisioning script
  config.vm.provision "shell", inline: <<-SHELL
    bash "/vagrant/utils/provision-debian.sh"
  SHELL
end
