#!/usr/bin/env bash

set +x

apt-get update
# Needed to install Tshark (and by extension, Wireshark) without any installation prompts
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get install -y git tshark linux-image-5.4.0-66-lowlatency linux-headers-5.4.0-66-lowlatency iperf3

# Set up the local user with a known password and add necessary permissions, set groups, and add home folder
useradd -m -d /home/netmon -s /bin/bash netmon
echo "netmon:netmon" | chpasswd
echo "netmon ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_netmon
chmod 440 /etc/sudoers.d/99_netmon
usermod -aG vboxsf netmon

mkdir /home/netmon/src

# Pull the OpenAirInterface and checkout the required version. The eNB and UE are always in distinct folders for increased usability.
BASE_DIR="/home/netmon/src"
cd "$BASE_DIR"
git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git enb_folder
cd enb_folder
git checkout v1.2.2
cd ..
cp -R enb_folder/ ue_folder

# Set necessary ownership
chown -R netmon:netmon /home/netmon/
