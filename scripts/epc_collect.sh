#!/usr/bin/env bash

echo "Starting application log and PCAP collection"
sudo rm -rf EPC
sudo mkdir -p EPC/oai-hss-cfg EPC/oai-mme-cfg EPC/oai-spgwc-cfg EPC/oai-spgwu-cfg EPC/hss-logs

echo "Collecting configuration files ..."
sudo -E docker cp mn.hss:/openair-hss/etc/. EPC/oai-hss-cfg
sudo -E docker cp mn.mme:/openair-mme/etc/. EPC/oai-mme-cfg
sudo -E docker cp mn.spgwc:/openair-spgwc/etc/. EPC/oai-spgwc-cfg
sudo -E docker cp mn.spgwu:/openair-spgwu-tiny/etc/. EPC/oai-spgwu-cfg

echo "Collecting log files ..."
sudo -E docker cp mn.hss:/openair-hss/hss_check_run.log EPC
sudo -E docker cp mn.hss:/openair-hss/logs/ EPC/hss-logs
sudo -E docker cp mn.mme:/openair-mme/mme_check_run.log EPC
sudo -E docker cp mn.spgwc:/openair-spgwc/spgwc_check_run.log EPC
sudo -E docker cp mn.spgwu:/openair-spgwu-tiny/spgwu_check_run.log EPC

echo "Collecting PCAP files ..."
sudo -E docker cp mn.hss:/tmp/hss_check_run.pcap EPC
sudo -E docker cp mn.mme:/tmp/mme_check_run.pcap EPC
sudo -E docker cp mn.spgwc:/tmp/spgwc_check_run.pcap EPC
sudo -E docker cp mn.spgwu:/tmp/spgwu_check_run.pcap EPC
sudo -E docker cp mn.forwarder:/tmp/forwarder_check_run.pcap EPC
sudo -E docker cp mn.iperf_dst:/tmp/iperf_dst_check_run.pcap EPC

filename="$(date '+%Y%m%d-%H%M%S')-epc-archives"
sudo -E zip -r -qq "$filename".zip EPC
echo "Saved all logs and PCAP files as archive with name: $filename"
