# -*- mode: ruby -*-
# vi: set ft=ruby :

"""
This Vagrantfile will set up 3 VMs, requiring up to 90GB total storage, 12GB RAM and at least 6 available cores.

These VMs are connected using the internal VBox Network and each has a NIC connected to the VBox NAT Network for Internet Access

The eNB and UE VMs use the same script for configuration and requires the user to manually build the binaries

The EPC machine requires the user to manually run the ansible-playbook located in FOP4/ansible
  - Any topology script must be run from within the FOP4 directory

"""

Vagrant.configure("2") do |config|
  # Dedicated VM for eNB and UE
  config.vm.define "enb" do |enb|
    # Using Ubuntu 18.04 Bionic Beaver
    enb.vm.box = "ubuntu/bionic64"

    # Using vagrant-disksize plugin
    enb.disksize.size = '20GB'

    # set name, ram, cpus
    enb.vm.provider "virtualbox" do |v|
      v.name = "ran"
      v.memory = 4096
      v.cpus = 2
      v.customize ["modifyvm", :id, "--natnet1", "192.168.72.0/24"]
    end

    enb.vm.network "private_network", ip: "10.10.1.2", virtualbox__intnet: true

    # Install required packages and build binaries
    enb.vm.provision "shell", path: "scripts/bootstrap_ran.sh"

    # Copy and move config files to correct locations
    enb.vm.provision "file", source: "config/lte-fdd-basic-sim.conf", destination: "~/"
    enb.vm.provision "shell", inline: "mv /home/vagrant/lte-fdd-basic-sim.conf /home/netmon/src/enb_folder/ci-scripts/conf_files/"

  end

  # VM for UE
  config.vm.define "ue" do |ue|
    ue.vm.box = "ubuntu/bionic64"
    ue.disksize.size = "20GB"

    ue.vm.provider "virtualbox" do |v|
      v.name = "ue"
      v.memory = 4096
      v.cpus = 2
      v.customize ["modifyvm", :id, "--natnet1", "192.168.72.0/24"]
    end

    ue.vm.network "private_network", ip: "10.10.1.3", virtualbox__intnet: true

    # Install required packages and build binaries
    ue.vm.provision "shell", path: "scripts/bootstrap_ran.sh"

    # Copy and move config files to correct locations
    ue.vm.provision "file", source: "config/ue_eurecom_test_sfr.conf", destination: "~/"
    ue.vm.provision "shell", source: "mv /home/vagrant/ue_eurecom_test_sfr.conf /home/netmon/src/enb_folder/openair3/NAS/TOOLS/ue_eurecom_test_sfr.conf"
  end

  # VM for EPC and FOP4 topology
  config.vm.define "epct" do |epct|
    epct.vm.box = 'ubuntu/bionic64'
    epct.disksize.size = '50GB'
    epct.vm.provider "virtualbox" do |v|
      v.name = "epct"
      v.memory = 4096
      v.cpus = 2
      v.customize ["modifyvm", :id, "--natnet1", "192.168.72.0/24"]
    end
    epct.vm.network "private_network", ip: "10.10.1.4", virtualbox__intnet: true
    epct.vm.provision "shell", path: "scripts/bootstrap_epc.sh"
  end
end
