#!/bin/sh

export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

BKP_NUM_TO_PRUNE=30
BKP_PRUNE_DOW=7
LOG='/borg_check.json'


DOW=`date +%u`
rm $LOG.tmp $LOG.tmp.list
touch $LOG.tmp
chmod 644 $LOG.tmp


find /home/ -name config | sed 's/config$//' | while read line ; do

	echo
	echo Proccessing: $line

	NAME=`echo $line | awk -F'/' '{print $3}'`


	if [ "$DOW" = "$BKP_PRUNE_DOW" ] # Time to prune?
	then

	    echo "Checking number of backup"
	    BKP_FACT=`borg list $line | wc -l` # How many backup are ready 
	    sleep 30

	    if [ "$BKP_FACT" -ge "$BKP_NUM_TO_PRUNE" ] ; then # Prune now!

		echo $line Prune backups now to $BKP_NUM_TO_PRUNE days.
		borg prune --stats --list --keep-within=$BKP_NUM_TO_PRUNE\d $line
		USER=`echo $line | awk -F'/' '{print $3}'`
		chown -R $NAME:$NAME $line

		sleep 30

	    else

		echo $line $BKP_FACT" < "$BKP_NUM_TO_PRUNE prune canceled.

	    fi
	fi

	echo -n "Check lock file: "
	# Check lock.exclusive
	LOCK=`ls -l "$line"lock.exclusive  | awk '{print $9}'`
	if [ -n "$LOCK" ]
	then
	    echo '        { "Host_name":"'$NAME'", "state":"Found LOCK! '$LOCK'" },' >>$LOG.tmp
	    continue
	fi

	# get size
	echo "Getting BORG info..."
	borg info --last 1 --json $line >$LOG.tmp.json

	sleep 10

	SIZE_1=`cat $LOG.tmp.json | grep  unique_csize`
	SIZE_2=`cat $LOG.tmp.json | grep  max_archive_size`
	rm $LOG.tmp.json

	# Last backup date check
	CURRENT_DATE=`date +%Y-%m-%d`
	echo -n "Checking date of last backup... "
	LAST_BKP=`borg list --short --last 1 $line | awk '{print $1}'`
	LAST_BKP_DATE=`echo $LAST_BKP | awk -F'_' '{print $1}'`
	echo $LAST_BKP_DATE
	sleep 10

	echo -n "Check database size... "
	DB_SIZE=`borg list $line::$LAST_BKP | grep 'mnt/db_bkp' | awk '{s += \$4} END {print s}'`	# Database size check
	echo $DB_SIZE
	if [ "$CURRENT_DATE" != "$LAST_BKP_DATE" ]
	then
	    echo '        { "Host_name":"'$NAME'", '$SIZE_1' '$SIZE_2', "Database_size":"'$DB_SIZE'", "state":"Last backup is too old! '$LAST_BKP_DATE'" },' >>$LOG.tmp
	    continue
	fi

	sleep 10

	echo -n "Check BORG reposotory consistency... "
	borg check --verify-data --show-rc --last 1 $line
	if [ $? -ne 0 ] ; then
	    echo '        { "Host_name":"'$NAME'", '$SIZE_1' '$SIZE_2', "Database_size":"'$DB_SIZE'", "state":"check FAIL!" },' >>$LOG.tmp
	else
	    echo '        { "Host_name":"'$NAME'", '$SIZE_1' '$SIZE_2', "Database_size":"'$DB_SIZE'", "state":"OK" },' >>$LOG.tmp
	fi

	echo "Restore permissions... "
	chown -R $NAME:$NAME $line

	sleep 120

done

