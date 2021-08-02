#!/usr/bin/env bash

# This script collects CPU and Memory usage from the BMV2 switch instances and the Disk IO of the EPC VM
# and writes these to a CSV file on a 5 second interval until keyboard interrupt.
# Disk IO is the difference between each 5 second measurement.

csv_filename="$(date +"%Y%m%d-%H%M")-metrics.csv"
touch $csv_filename
echo "timestamp,pid1,cpu1,mem1,pid2,cpu2,mem2,kb_wrtn" >> $csv_filename

# First time reading Disk IO.
disk_io_previous=$(iostat -d sda | tail -n 2 | xargs | awk '{print $6}')

# Until keyboard interrupt
while true
do
  # Current time
  timestamp=$(date +"%Y%m%d-%H%M%S")

  # CPU and Memory usage of BMV2 switch instances
  cpu_mem_usage=$(pgrep simple_switch | xargs -I % top -b -n 1 -p % | grep simple_switch | awk '{print $1 "," $9 "," $10 ","}' | tr -d '\n' | sed 's/.$//')

  # Current Disk IO
  disk_io_current=$(iostat -d sda | tail -n 2 | xargs | awk '{print $6}')

  # Difference since last measurement
  disk_io_diff=$(($disk_io_current-$disk_io_previous))

  # Write timestamp and metrics to CSV file
  echo "$timestamp,$cpu_mem_usage,$disk_io_diff" >> $csv_filename

  # Set current Disk IO measurement as previous
  disk_io_previous=$disk_io_current

  sleep 5
done
