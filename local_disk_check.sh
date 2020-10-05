#!/bin/bash
# Script to warn us if local disk on gitlab04 exceeds a threshold.
# QDR 05 Oct 2020

# Get percentage use of local disk
pct=`df --output=pcent /dev/sda1 | tr -dc '0-9'`

# Create logfile if it does not yet exist
logfile="/research-home/rblake/gitlab_disk_warning_log.txt"
touch $logfile

# Check whether email has already been sent today
mailsent=$(grep -E "warning.*`date +"%Y.%m.%d"`" $logfile)

# If percentage use is over 90% send an email if none have been sent today
if [ $pct -ge "90" ] && [ -z "$mailsent" ]; then
	mail -s "Warning: gitlab04 local disk is ${pct}% full!" qread@umd.edu,rblake1@umd.edu,tking112@umd.edu < /dev/null
	echo "warning sent on $(date +%Y.%m.%d)" >> $logfile
fi
