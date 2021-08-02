#!/usr/bin/python

"""
This topology was designed to investigate a problem with high TCP retransmissions between UE and Iperf3 server.

A simple Iperf3 test between a new node connected directly to SPGW-U and the Iperf3 server show no increase
in TCP retransmissions with high bandwidth (30mbps).

We conclude that TCP retransmissions will increase with higher bandwidths between the UE and Iperf3 server.
"""

from mininet.net import Containernet
from mininet.node import Controller, Node, OVSKernelSwitch
from mininet.cli import CLI
from mininet.link import TCLink
from mininet.log import info, setLogLevel
from mininet.bmv2 import Bmv2Switch, P4DockerHost


setLogLevel('info')


net = Containernet(controller=Controller)

info('*** Adding controller\n')
net.addController('c0')

info('*** Adding docker containers\n')
# EPC
hss = net.addDocker('hss',
                    cls=P4DockerHost,
                    ip='192.168.61.2/24',
                    dimage='oai-hss:production')
mme = net.addDocker('mme',
                    cls=P4DockerHost,
                    ip='192.168.61.3/24',
                    dimage='oai-mme:production')
spgw_c = net.addDocker('spgwc',
                    cls=P4DockerHost,
                    ip='192.168.61.4/24',
                    dimage='oai-spgwc:production')
spgw_u = net.addDocker('spgwu',
                    cls=P4DockerHost,
                    ip='192.168.61.5/24',
                    dimage='oai-spgwu-tiny:production')
# Segment for testing monitoring
forwarder = net.addDocker('forwarder',
                    cls=P4DockerHost,
                    ip='192.168.62.3/24',
                    mac='00:00:00:00:00:F3',
                    dimage='forwarder:1804')
iperf_dst = net.addDocker('iperf_dst',
                    cls=P4DockerHost,
                    ip='192.168.63.3/24',
                    mac='00:00:00:00:00:D3',
                    dimage='iperf:1804')
iperf_cli = net.addDocker('iperf_cli',
                    cls=P4DockerHost,
                    ip='192.168.61.6/24',
                    dimage='iperf:1804')

info('*** Adding core switch\n')
s1 = net.addSwitch('s1', cls=OVSKernelSwitch)

info('*** Adding BMV2 switches\n')
s2 = net.addSwitch('s2', cls=Bmv2Switch, json='./forwarder.json', switch_config='./s2f_commands.txt')
s3 = net.addSwitch('s3', cls=Bmv2Switch, json='./forwarder.json', switch_config='./s3f_commands.txt')

info('*** Creating links\n')
net.addLink(hss, s1)
net.addLink(mme, s1)
net.addLink(spgw_c, s1)
net.addLink(spgw_u, s1)
net.addLink(spgw_u, s2, intfName1='spgwu-eth2', port1=2, port2=1)
net.addLink(forwarder, s2, intfName1='forwarder-eth2', port1=1, port2=2)
net.addLink(forwarder, s3, intfName1='forwarder-eth3', port1=2, port2=1)
net.addLink(iperf_dst, s3, port2=2)
net.addLink(iperf_cli, s1)

info('*** Setting up additional interfaces on: forwarder, spgwu_u\n')
# Set MAC and IP on new interfaces
spgw_u.setMAC(mac='00:00:00:00:00:F2', intf='spgwu-eth2')
spgw_u.setIP(ip='192.168.62.2', prefixLen=24, intf='spgwu-eth2')
forwarder.setMAC(mac='00:00:00:00:00:D2', intf='forwarder-eth3')
forwarder.setIP(ip='192.168.63.2', prefixLen=24, intf='forwarder-eth3')

info('*** Setting up forwarding on: forwarder\n')
# set up forwarding
forwarder.cmd('iptables -P FORWARD ACCEPT')
forwarder.cmd('sysctl net.ipv4.conf.all.forwarding=1')

info('*** Starting network\n')
net.start()
net.staticArp()

info('*** Setting up additional ARP\n')
# Some ARP entries must be manually added:
forwarder.setARP('192.168.62.2', '00:00:00:00:00:F2')
forwarder.setARP('192.168.63.3', '00:00:00:00:00:D3')
iperf_dst.setARP('192.168.63.2', '00:00:00:00:00:D2')

info('*** Setting up additional routing\n')
# Set up appropriate routing for hosts connected to more than one network
spgw_u.cmd('ip route add 192.168.63.0/24 via 192.168.62.3')
forwarder.cmd('ip route add 12.1.1.0/24 via 192.168.62.2')
iperf_dst.cmd('ip route add 192.168.62.0/24 via 192.168.63.2')
iperf_dst.cmd('ip route add 12.1.1.0/24 via 192.168.63.2')
iperf_cli.cmd('ip route add 192.168.63.0/24 via 192.168.61.5')

info('*** Disabling TCP checksum verification on hosts: iperf_dst, forwarder, spgw_u\n')
# Don't verify TCP checksums, as BMV2 switches change this up and causes TCP packets to be dropped by the kernel:
iperf_dst.cmd('ethtool --offload iperf_dst-eth0 rx off tx off')
forwarder.cmd('ethtool --offload forwarder-eth2 rx off tx off')
forwarder.cmd('ethtool --offload forwarder-eth3 rx off tx off')
spgw_u.cmd('ethtool --offload spgwu-eth2 rx off tx off')

info('*** Running CLI\n')
CLI(net)

info('*** Stopping network')
net.stop()
