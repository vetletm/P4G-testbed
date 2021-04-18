#!/usr/bin/env bash

set +x

apt-get update
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections

DEBIAN_FRONTEND=noninteractive apt-get install -y git tshark linux-image-5.4.0-66-lowlatency linux-headers-5.4.0-66-lowlatency iperf3

useradd -m -d /home/netmon -s /bin/bash netmon
echo "netmon:netmon" | chpasswd
echo "netmon ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_netmon
chmod 440 /etc/sudoers.d/99_netmon
usermod -aG vboxsf netmon

mkdir /home/netmon/src

BASE_DIR="/home/netmon/src"
cd "$BASE_DIR"
git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git enb_folder
cd enb_folder
git checkout v1.2.2
cd ..
cp -R enb_folder/ ue_folder

chown -R netmon:netmon /home/netmon/
