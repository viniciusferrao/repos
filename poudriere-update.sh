#!/bin/sh
# Script update dos pacotes do Poudriere FreeBSD
#
# Releases
# 1.0: Initial Release

echo "Starting Poudriere updates..."

# PID Control
PIDFILE=/var/run/poudriere-update.pid

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

# Update procedure
JAILNAME=$1
PORTSTREE=$2

POUDRIERE_DIR="/usr/local/etc/poudriere.d"
PATH="$PATH:/usr/local/bin"

if [ -z "$JAILNAME" ]; then
#       printf "Provide a jail name please.\n"
#       exit 1
        printf "Updating all jails, since no one was specified\n"
        JAILNAME=`poudriere jail -l | awk '{ print $1 }' | grep -v JAILNAME`
fi

if [ -z "$PORTSTREE" ]; then
        PORTSTREE="default"
fi

# check that the ports tree exists
poudriere ports -l | grep "^$PORTSTREE" > /dev/null
if [ $? -gt 0 ]; then
        printf "No such ports tree ($PORTSTREE)\n"
        exit 2
fi

## check that there's a list of packages for that jail
for x in $JAILNAME ; do
        if [ ! -f "$POUDRIERE_DIR/$x.pkglist" ]; then
                printf "No such file (list of packages: $POUDRIERE_DIR/$x.pkglist\n"
                exit 3
        fi
done

# check that the jail is there
for x in $JAILNAME ; do
        poudriere jails -l | grep "^$x" > /dev/null
        if [ $? -gt 0 ]; then
                printf "No such jail ($x)\n"
                exit 4
        fi
done

# update the ports tree
poudriere ports -u -p $PORTSTREE

# Update jails before compilations
for x in $JAILNAME ; do
        printf "Updating jail $x\n"
        poudriere jail -u -j $x
done

# build new packages
for x in $JAILNAME ; do
        printf "Compiling packages for $x\n"
        poudriere bulk -f /usr/local/etc/poudriere.d/$x.pkglist -j $x -p $PORTSTREE
done

# Clean up of the PID file
rm $PIDFILE
