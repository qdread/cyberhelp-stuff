for dir in */; do
	cd /mnt/c/Users/qread/Documents/GitHub/sesync_repos/$dir
	oldurl=`git remote -v | head -1 | awk '{print $2}'`
	# Replace the two strings
	newurl=`echo $oldurl | sed 's/https:\/\/github.com\//git@github.com:/'`
	newurl=`echo $newurl | sed 's/https:\/\/gitlab.sesync.org\//git@gitlab.sesync.org:/'`
	git remote set-url origin $newurl
done
	
for dir in */; do
	cd /research-home/qread/lesson_repos/$dir
	git remote -v
done
