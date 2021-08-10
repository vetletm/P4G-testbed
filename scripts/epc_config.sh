#!/usr/bin/env bash
echo "Configuring HSS"
sudo -E docker cp ./hss-cfg.sh mn.hss:/openair-hss/scripts
sudo -E docker exec -it mn.hss /bin/bash -c "cd /openair-hss/scripts && chmod 777 hss-cfg.sh && ./hss-cfg.sh"

echo "Configuring MME"
sudo -E docker cp ./mme-cfg.sh mn.mme:/openair-mme/scripts
sudo -E docker exec -it mn.mme /bin/bash -c "cd /openair-mme/scripts && chmod 777 mme-cfg.sh && ./mme-cfg.sh"

echo "Configuring SPGW-C"
sudo -E docker cp ./spgwc-cfg.sh mn.spgwc:/openair-spgwc
sudo -E docker exec -it mn.spgwc /bin/bash -c "cd /openair-spgwc && chmod 777 spgwc-cfg.sh && ./spgwc-cfg.sh"

echo "Configuring SPGW-U"
sudo -E docker cp ./spgwu-cfg.sh mn.spgwu:/openair-spgwu-tiny
sudo -E docker exec -it mn.spgwu /bin/bash -c "cd /openair-spgwu-tiny && chmod 777 spgwu-cfg.sh && ./spgwu-cfg.sh"
