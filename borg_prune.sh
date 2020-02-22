#!/bin/sh

export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

BKP_NUM=30

find /home/ -name config | sed 's/config$//' | while read line ; do

    BKP_FACT=`borg list $line | wc -l`

    sleep 30

    if [ "$BKP_FACT" -ge "$BKP_NUM" ] ; then

	echo $line Prune now to $BKP_NUM backups.

	borg prune --stats --list --keep-within=$BKP_NUM\d $line
	USER=`echo $line | awk -F'/' '{print $3}'`
	chown -R $USER:$USER $line

	sleep 30

    else

	echo $line $BKP_FACT" < "$BKP_NUM prune canceled.

    fi

done
