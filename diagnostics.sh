#!/bin/bash
# Get percentage use of research-homedirs
pct=`df --output=pcent /research-home/qread | tr -dc '0-9'`

# Get node status of Slurm nodes
nodestatus=`sinfo -p sesync,sesyncshared --Format="nodeaiot" | tail -1`

# Get the number of nodes in "other", meaning bad, status
IFS='/' read -r -a nbadnodes <<< "$nodestatus"

logfile="/research-home/qread/diagnostic_emaillog.txt"

# Check whether emails have already been sent today
researchmailsent=$(grep -E "research.*`date +"%Y.%m.%d"`" $logfile)
slurmmailsent=$(grep -E "slurm.*`date +"%Y.%m.%d"`" $logfile)

# If percentage use is over 90% send myself an email if none have been sent today
if [ $pct -ge "90" ] && [ -z "$researchmailsent" ]; then
	mail -s "Research Homedirs is ${pct}% full!!! Do something, Q!" qread@sesync.org < /dev/null
	echo "research homedirs warning sent on $(date +%Y.%m.%d)" >> $logfile
fi
	
# If at least 6 of the slurm nodes are down or drained send myself an email
if [ ${nbadnodes[2]} -ge "6" ] && [ -z "$slurmmailsent" ]; then
	mail -s "${nbadnodes[2]} of the slurm nodes are in a bad state!!! Do something, Q!" qread@sesync.org < /dev/null
	echo "slurm nodes warning sent on $(date +%Y.%m.%d)" >> $logfile
fi

