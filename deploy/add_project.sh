#!/bin/sh

DEST_HOST=$1
DEST_HOST_FIX=`echo $1 | sed s/\\\./_/g`

ssh-keygen -R $DEST_HOST
ssh-keyscan -t rsa $DEST_HOST >>/root/.ssh/known_hosts


HNAME=`ssh $DEST_HOST hostname | sed s/\\\./_/g`
SRV_HNAME=`hostname -A | awk '{print $1}'`
echo $HNAME

if [ "$HNAME" = "$DEST_HOST_FIX" ] ; then

    useradd -m $DEST_HOST_FIX

    ssh $DEST_HOST mkdir /etc/borg
    ssh $DEST_HOST ssh-keygen -t rsa -b 4096 -f /etc/borg/ssh_key

    mkdir -p /home/$DEST_HOST_FIX/.ssh

    echo -n 'command="/usr/bin/borg serve --append-only --restrict-to-path /home/'$DEST_HOST_FIX'/'$DEST_HOST_FIX'",restrict ' >/home/$DEST_HOST_FIX/.ssh/authorized_keys
    ssh $DEST_HOST cat /etc/borg/ssh_key.pub >>/home/$DEST_HOST_FIX/.ssh/authorized_keys
    chown -R $DEST_HOST_FIX:$DEST_HOST_FIX /home/$DEST_HOST_FIX
    chmod 644 /home/$DEST_HOST_FIX/.ssh/authorized_keys

    ssh $DEST_HOST rm /etc/borg/last.log /etc/borg/borg_backup /etc/cron.d/borg /etc/cron.d/borg_cron /usr/bin/borg /root/.ssh/config

    scp borg_backup $DEST_HOST:/etc/borg/
    scp borg_cron   $DEST_HOST:/etc/cron.d/
    scp borg-1.1.10 $DEST_HOST:/usr/bin/

    ssh $DEST_HOST "echo -n "$SRV_HNAME"		 >/etc/borg/server_naame"

    ssh $DEST_HOST "echo 'Host "$SRV_HNAME"'		 >/root/.ssh/config"
    ssh $DEST_HOST "echo '    Hostname "$SRV_HNAME"'	>>/root/.ssh/config"
    ssh $DEST_HOST "echo '    CheckHostIP no'		>>/root/.ssh/config"

    ssh $DEST_HOST ln -s /usr/bin/borg-1.1.10 /usr/bin/borg
    ssh $DEST_HOST chmod 755 /usr/bin/borg-1.1.10
    ssh $DEST_HOST chmod 755 /usr/bin/borg
    ssh $DEST_HOST service cron restart

    ssh $DEST_HOST ssh-keygen -R $SRV_HNAME
    ssh $DEST_HOST "ssh-keyscan -t rsa "$SRV_HNAME" >>/root/.ssh/known_hosts"
    ssh $DEST_HOST "export BORG_RSH='ssh -i /etc/borg/ssh_key' ; borg init -e none ssh://$DEST_HOST_FIX@"$SRV_HNAME"/./$DEST_HOST_FIX"

else

    echo Bad hostname: $HNAME != $DEST_HOST_FIX

fi

