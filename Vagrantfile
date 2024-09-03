# -*- mode: ruby -*-
# vi: set ft=ruby :

if Vagrant.has_plugin?("dotenv")
  require "dotenv/load"
end

# environment variables used for customizations
vm_cpus = ENV['VM_NUM_CPUS'] || 4
vm_memory = ENV['VM_MEMORY'] || '4096'

Vagrant.configure('2') do |config|
  # we need a Debian-like distro for kernel .deb generation
  config.vm.box = 'debian/bookworm64'

  # Disable automatic box update checking
  # config.vm.box_check_update = false

  # use rsync for one-way syncing of scripts
  config.vm.synced_folder \
    '.', '/vagrant', type: 'rsync', rsync__chown: false, rsync__auto: true, \
    rsync__exclude: ['.git/', '.vagrant/', 'dist/']

  config.vm.provider 'virtualbox' do |vbox|
    vbox.cpus = vm_cpus
    vbox.memory = vm_memory
    # use bidirectional sharing for the dist/ folder
    config.vm.synced_folder './dist', '/vagrant/dist', owner: '1000'
  end
  config.vm.provider 'libvirt' do |libvirt|
    libvirt.cpus = vm_cpus
    libvirt.memory = vm_memory
    # use bidirectional sharing for the dist/ folder
    config.vm.synced_folder './dist', '/vagrant/dist', type: '9p', disabled: false, \
      accessmode: 'squash', owner: '1000'
  end

  # Run provisioning script
  config.vm.provision 'shell', inline: <<-SHELL
    bash '/vagrant/utils/provision-debian.sh'
  SHELL
end
