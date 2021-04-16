# ACIT5930-artefact
OAI 4G RAN and EPC running in VBox 

### Purpose of this project
This will act as the artefact for my Master's thesis. The thesis aims to investigate the performance impact of In-Band Network Telemetry (INT) on a 4G LTE EPC realized as Virtualized Network Functions (VNF). The repository contains all the necessary code and scripts to deploy a functional RAN and EPC in a VirtualBox environment.

### Requirements
Hardware requirements:
- At least 16GB of RAM
- Ideally a 4-core CPU with Hyperthreading or Simultaneous Multi Threading (i.e. Intel or AMD)
- At least 120GB of free storage. RAN and UE VMs require 20GB each, the EPC VM requires 50GB. 

The setup has been tested on the following specs:
- Ryzen 5 2600X 6-core @3.8GHz
- 32GB DDR4 RAM
- 960GB HDD

Platform:
- OS: Ubuntu 18.04.5 LTS x86_64
- Kernel version: 5.4.0-71-generic

Software:
- Vagrant 2.2.10

### Overview
The setup runs on three VMs interconnected with a internal network with the range `10.10.1.0/24`. The VBox NAT network has been changed to the range `192.168.72.0/24`. 
