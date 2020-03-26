# Count number of active users on rstudio server by counting the number of -u in the active-sessions output
users=$(/usr/sbin/rstudio-server active-sessions | grep -c \\-u)

# Get node status of Slurm nodes, replace slashes with commas so it can go into the csv
# Format is active, idle, other (i.e. down), and total, so we only need to keep the first 3 numbers.
nodestatus=$(sinfo -p sesync,sesyncshared --Format="nodeaiot" | 
	tail -1 | 
	awk -F '\/' '{print $1","$2","$3}')
	
# Append output to a file, with date.
echo $(date +%F),$users,$nodestatus >> /nfs/public-data/cyberhelp/usage_logs/active_users.csv
