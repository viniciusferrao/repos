#!/bin/sh
# Script para mirroring do FreeBSD
#
# Releases
# 1.0: Initial Release

echo "Starting FreeBSD mirroring..."

# PID Control
PIDFILE=/var/run/freebsd-repo-update.pid
if [ -f $PIDFILE ]
then
        PID=$(cat $PIDFILE)
        ps -p $PID > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
                echo "Process already running"
                exit 1
        else
                ## Process not found assume not running
                echo $$ > $PIDFILE
                if [ $? -ne 0 ]
                then
                        echo "Could not create PID file"
                        exit 1
                fi
        fi
else
        echo $$ > $PIDFILE
        if [ $? -ne 0 ]
        then
                echo "Could not create PID file"
                exit 1
        fi
fi

# Mirror the main FreeBSD tree
/usr/local/bin/rsync -vaHz --delete ftp6.us.FreeBSD.org::FreeBSD/ /nfs/repos/FreeBSD/
#/usr/local/bin/rsync -vaHz --delete ftp2.us.FreeBSD.org::FreeBSD/ /nfs/repos/FreeBSD/

# Only mirror production releases updates
# Information is gotten in the ISO-IMAGES of the main mirror
echo "Mirroring FreeBSD updates with parallel fetches..."

RELEASES=`ls /nfs/repos/freebsd/releases/ISO-IMAGES/`

for x in $RELEASES ; do
        if [ ! -d /nfs/repos/freebsd-update/$x-RELEASE ] ; then
                mkdir /nfs/repos/freebsd-update/$x-RELEASE
        fi
        if [ ! -d /nfs/repos/freebsd-update/to-$x-RELEASE ] ; then
                mkdir /nfs/repos/freebsd-update/to-$x-RELEASE
        fi

        echo Fetching $x-RELEASE:
        /usr/local/bin/lftp -c 'open -e "mirror --delete --only-newer '"$x-RELEASE"' /nfs/repos/freebsd-update/'"$x-RELEAE"'" http://update6.freebsd.org' > /dev/null 2>&1 &
        #usr/local/bin/lftp -c 'open -e "mirror --delete --only-newer '"$x-RELEASE"' /nfs/repos/freebsd-update/'"$x-RELEASE"'" http://update3.freebsd.org'&
        echo Fetching to-$x-RELEASE:
        /usr/local/bin/lftp -c 'open -e "mirror --delete --only-newer '"to-$x-RELEASE"' /nfs/repos/freebsd-update/'"to-$x-RELEASE"'" http://update3.freebsd.org' > /dev/null 2>&1 &
        #/usr/local/bin/lftp -c 'open -e "mirror --delete --only-newer '"to-$x-RELEASE"' /nfs/repos/freebsd-update/'"to-$x-RELEASE"'" http://update3.freebsd.org' &
done

# Wait for all parallel jobs to finish
wait

# Remove EOL FreeBSD updates
# Use a find command without recursevely go through the directories
# and use grep in exclusion mode to remove all production releases
# If something is found then rm -rf would remove it, since it's EOL
FINDCOMMAND="find /nfs/repos/freebsd-update -type d -mindepth 1 -maxdepth 1"

for x in $RELEASES ; do
        FINDCOMMAND="$FINDCOMMAND | grep -v $x | grep to-"
done

RESULT=$(eval $FINDCOMMAND)

for x in $RESULT ; do
        rm -rf $x
done

# Clean up of the PID file
rm $PIDFILE

