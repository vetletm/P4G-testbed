#!/usr/bin/env bash
# Sets up all containers with Tshark for Packet Capturing

echo "Starting Tshark on all FOP4 network hosts: HSS, MME, SPGW-C, SPGW-U, Forwarder, Iperf_dst"
# Start network logs
sudo -E docker exec -d mn.hss /bin/bash -c "nohup tshark -i hss-eth0 -i eth0 -w /tmp/hss_check_run.pcap 2>&1 > /dev/null"
sudo -E docker exec -d mn.mme /bin/bash -c "nohup tshark -i mme-eth0 -i lo:s10 -i eth0 -w /tmp/mme_check_run.pcap 2>&1 > /dev/null"
sudo -E docker exec -d mn.spgwc /bin/bash -c "nohup tshark -i spgwc-eth0 -i lo:p5c -i lo:s5c -w /tmp/spgwc_check_run.pcap 2>&1 > /dev/null"
sudo -E docker exec -d mn.spgwu /bin/bash -c "nohup tshark -i any -w /tmp/spgwu_check_run.pcap 2>&1 > /dev/null"
sudo -E docker exec -d mn.forwarder /bin/bash -c "nohup tshark -i forwarder-eth2 -i forwarder-eth3 -w /tmp/forwarder_check_run.pcap 2>&1 > /dev/null"
sudo -E docker exec -d mn.iperf_dst /bin/bash -c "nohup tshark -i iperf_dst-eth0 -w /tmp/iperf_dst_check_run.pcap 2>&1 > /dev/null"
