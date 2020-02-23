#!/bin/sh

export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

LOG='/borg_check.json'

rm $LOG.tmp $LOG.tmp.list
touch $LOG.tmp
chmod 644 $LOG.tmp

find /home/ -name config | sed 's/config$//' | while read line ; do

	echo
	echo $line

	NAME=`echo $line | awk -F'/' '{print $3}'`

	# Check lock.exclusive
	LOCK=`ls -l "$line"lock.exclusive  | awk '{print $9}'`
	if [ -n "$LOCK" ]
	then
	    echo '        { "Host_name":"'$NAME'", "state":"Found LOCK! '$LOCK'" },' >>$LOG.tmp
	    continue
	fi

	# get size
	borg info --last 1 --json $line >$LOG.tmp.json

	sleep 10

	SIZE_1=`cat $LOG.tmp.json | grep  unique_csize`
	SIZE_2=`cat $LOG.tmp.json | grep  max_archive_size`
	rm $LOG.tmp.json

	# Last backup date check
	CURRENT_DATE=`date +%Y-%m-%d`
	LAST_BKP=`borg list --short --last 1 $line | awk '{print $1}'`
	LAST_BKP_DATE=`echo $LAST_BKP | awk -F'_' '{print $1}'`

	sleep 10
	DB_SIZE=`borg list $line::$LAST_BKP | grep 'mnt/db_bkp' | awk '{s += \$4} END {print s}'`	# Database size check

	if [ "$CURRENT_DATE" != "$LAST_BKP_DATE" ]
	then
	    echo '        { "Host_name":"'$NAME'", '$SIZE_1' '$SIZE_2', "Database_size":"'$DB_SIZE'", "state":"Last backup is too old! '$LAST_BKP_DATE'" },' >>$LOG.tmp
	    continue
	fi

	sleep 10

	# Check BORG consistency
	borg check --verify-data --show-rc --last 1 $line
	if [ $? -ne 0 ] ; then
	    echo '        { "Host_name":"'$NAME'", '$SIZE_1' '$SIZE_2', "Database_size":"'$DB_SIZE'", "state":"check FAIL!" },' >>$LOG.tmp
	else
	    echo '        { "Host_name":"'$NAME'", '$SIZE_1' '$SIZE_2', "Database_size":"'$DB_SIZE'", "state":"OK" },' >>$LOG.tmp
	fi

	chown -R $NAME:$NAME $line

	sleep 120

done
