#!/usr/bin/env bash

csv_filename="$(date +"%Y%m%d-%H%M")-metrics.csv"
touch $csv_filename
echo "timestamp,pid1,cpu1,mem1,pid2,cpu2,mem2,kb_wrtn" >> $csv_filename

disk_io_previous=$(iostat -d sda | tail -n 2 | xargs | awk '{print $6}')

while true
do
  timestamp=$(date +"%Y%m%d-%H%M%S")
  cpu_mem_usage=$(pgrep simple_switch | xargs -I % top -b -n 1 -p % | grep simple_switch | awk '{print $1 "," $9 "," $10 ","}' | tr -d '\n' | sed 's/.$//')
  disk_io_current=$(iostat -d sda | tail -n 2 | xargs | awk '{print $6}')
  disk_io_diff=$(($disk_io_current-$disk_io_previous))
  echo "$timestamp,$cpu_mem_usage,$disk_io_diff" >> $csv_filename
  disk_io_previous=$disk_io_current
  sleep 5
done
