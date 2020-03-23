# Get percentage use of research-homedirs
pct=`df --output=pcent /research-home/qread | tr -dc '0-9'`

# Get node status of Slurm nodes
nodestatus=`sinfo -p sesync,sesyncshared --Format="nodeaiot" | tail -1`

# Get the number of nodes in "other", meaning bad, status
IFS='/' read -r -a nbadnodes <<< "$nodestatus"

# If percentage use is over 95% send myself an email
if [ $pct -ge "95" ]; then
	mail -s "Research Homedirs is over 95% full!!! Do something, Q!" qread@sesync.org < /dev/null
fi
	
# If over half of the slurm nodes are down or drained send myself an email
if [ ${nbadnodes[2]} -ge "12" ]; then
	mail -s "Over half the slurm nodes are in a bad state!!! Do something, Q!" qread@sesync.org < /dev/null
fi
