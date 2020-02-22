#!/bin/sh

export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes


find /home/ -name config | sed 's/config$//' | while read line ; do

    borg prune --stats --list --keep-daily 30 $line
    USER=`echo $line | awk -F'/' '{print $3}'`
    chown -R $USER:$USER $line

    sleep 30

done
