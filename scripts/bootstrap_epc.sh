#!/usr/bin/env bash


useradd -m -d /home/netmon -s /bin/bash netmon
echo "netmon:netmon" | chpasswd
echo "netmon ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_netmon
chmod 440 /etc/sudoers.d/99_netmon
usermod -aG vboxsf netmon

mkdir -p /home/netmon/src/openair-components
chown -R netmon:netmon /home/netmon/src

BASE_DIR="/home/netmon/src"
EPC_DIR="/home/netmon/src/openair-components"
sudo apt-get update
sudo apt-get install git


git clone --branch fop4_extension_new https://github.com/vetletm/openair-hss.git "$EPC_DIR/openair-hss"
git clone --branch fop4_extension_new https://github.com/vetletm/openair-mme.git "$EPC_DIR/openair-mme"
git clone --branch fop4_extension_new https://github.com/vetletm/openair-spgwc.git "$EPC_DIR/openair-spgwc"
git clone --branch fop4_extension_new https://github.com/vetletm/openair-spgwu-tiny.git "$EPC_DIR/openair-spgwu-tiny"
git clone --branch vetletm-fix-ansible https://github.com/vetletm/FOP4 "$BASE_DIR/FOP4"
git clone https://github.com/OPENAIRINTERFACE/openair-epc-fed.git "$BASE_DIR/openair-epc-fed"

cd "$EPC_DIR"
cd openair-hss
sudo -E docker build --target oai-hss --tag oai-hss:production --file docker/Dockerfile.ubuntu18.04 .
cd "$EPC_DIR"

cd openair-mme
sudo -E docker build --target oai-mme --tag oai-mme:production --file docker/Dockerfile.ubuntu18.04
cd "$EPC_DIR"

cd openair-spgwc
sudo -E docker build --target oai-spgwc --tag oai-spgwc:production --file docker/Dockerfile.ubuntu18.04 .
cd "$EPC_DIR"

cd openair-spgwc
sudo -E docker build --target oai-spgwc --tag oai-spgwc:production --file docker/Dockerfile.ubuntu18.04 .
cd "$BASE_DIR"

git clone https://github.com/jafingerhut/p4-guide "$BASE_DIR/p4-guide"
cd "$BASE_DIR"
# This script calls exit on finish, nothing can be done after it through vagrant.
./p4-guide/bin/install-p4dev-v2.sh |& tee log.txt
