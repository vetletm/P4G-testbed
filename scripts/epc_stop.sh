#!/usr/bin/env bash

echo "Sending SIGINT to EPC component processes and Tshark ..."
sudo -E docker exec -it mn.hss /bin/bash -c "killall --signal SIGINT oai_hss tshark"
sudo -E docker exec -it mn.mme /bin/bash -c "killall --signal SIGINT oai_mme tshark"
sudo -E docker exec -it mn.spgwc /bin/bash -c "killall --signal SIGINT oai_spgwc tshark"
sudo -E docker exec -it mn.spgwu /bin/bash -c "killall --signal SIGINT oai_spgwu tshark"

echo "Sleeping 10 seconds and then sending SIGKILL to EPC component processes and Tshark"
sleep 10
sudo -E docker exec -it mn.hss /bin/bash -c "killall --signal SIGKILL oai_hss tshark tcpdump"
sudo -E docker exec -it mn.mme /bin/bash -c "killall --signal SIGKILL oai_mme tshark tcpdump"
sudo -E docker exec -it mn.spgwc /bin/bash -c "killall --signal SIGKILL oai_spgwc tshark tcpdump"
sudo -E docker exec -it mn.spgwu /bin/bash -c "killall --signal SIGKILL oai_spgwu tshark tcpdump"
