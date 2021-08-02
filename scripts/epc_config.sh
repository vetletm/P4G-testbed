#!/usr/bin/env bash

sudo docker run --name prod-cassandra -d -e CASSANDRA_CLUSTER_NAME="OAI HSS Cluster" \
             -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch cassandra:2.1
sudo docker cp openair-hss/src/hss_rel14/db/oai_db.cql prod-cassandra:/home
sudo docker exec -it prod-cassandra /bin/bash -c "nodetool status"
Cassandra_IP=`sudo docker inspect --format="{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" prod-cassandra`
sudo docker exec -it prod-cassandra /bin/bash -c "cqlsh --file /home/oai_db.cql ${Cassandra_IP}"

HSS_IP='192.168.61.2'
MME_IP='192.168.61.3'
SPGW0_IP='192.168.61.4'

python3 openair-hss/ci-scripts/generateConfigFiles.py --kind=HSS --cassandra=${Cassandra_IP} \
          --hss_s6a=${HSS_IP} --apn1=apn1.simula.nornet --apn2=apn2.simula.nornet \
          --users=200 --imsi=242881234500001 \
          --ltek=449C4B91AEACD0ACE182CF3A5A72BFA1 --op=1006020F0A478BF6B699F15C062E42B3 \
          --nb_mmes=1 --from_docker_file

python3 openair-mme/ci-scripts/generateConfigFiles.py --kind=MME \
          --hss_s6a=${HSS_IP} --mme_s6a=${MME_IP} \
          --mme_s1c_IP=${MME_IP} --mme_s1c_name=mme-eth0 \
          --mme_s10_IP=${MME_IP} --mme_s10_name=mme-eth0 \
          --mme_s11_IP=${MME_IP} --mme_s11_name=mme-eth0 --spgwc0_s11_IP=${SPGW0_IP} \
          --mcc=242 --mnc=88 --tac_list="5 6 7" --from_docker_file

python3 openair-spgwc/ci-scripts/generateConfigFiles.py --kind=SPGW-C \
          --s11c=spgwc-eth0 --sxc=spgwc-eth0 --apn=apn1.simula.nornet \
          --dns1_ip=8.8.8.8 --dns2_ip=8.8.4.4 --from_docker_file

python3 openair-spgwu-tiny/ci-scripts/generateConfigFiles.py --kind=SPGW-U \
          --sxc_ip_addr=${SPGW0_IP} --sxu=spgwu-eth0 --s1u=spgwu-eth0 --from_docker_file

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
