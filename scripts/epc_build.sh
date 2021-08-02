mkdir openair-components
cd openair-components

# For the EPC components, we're using slightly customized forks to allow them to be controlled by FOP4
# HSS
git clone --branch fop4_extension_new https://github.com/vetletm/openair-hss.git
cd openair-hss
sudo -E docker build --target oai-hss --tag oai-hss:production --file docker/Dockerfile.ubuntu18.04 .
cd ..

# MME
git clone --branch fop4_extension_new https://github.com/vetletm/openair-mme.git
cd openair-mme
sudo -E docker build --target oai-mme --tag oai-mme:production --file docker/Dockerfile.ubuntu18.04 .
cd ..

# SPGW-C
git clone --branch fop4_extension_new https://github.com/vetletm/openair-spgwc.git
cd openair-spgwc
sudo -E docker build --target oai-spgwc --tag oai-spgwc:production --file docker/Dockerfile.ubuntu18.04 .
cd ..

# SPGW-U
git clone --branch fop4_extension_new https://github.com/vetletm/openair-spgwu-tiny.git
cd openair-spgwu-tiny
sudo -E docker build --target oai-spgwu-tiny --tag oai-spgwu-tiny:production --file docker/Dockerfile.ubuntu18.04 .
cd ..

sudo -E docker image prune --force