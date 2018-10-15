#!/bin/sh
#
# Update Script para download de arquivos necessarios para PXEBoot das distribuições
# Debian 9 "Stretch" amd64/i386
# Debian 8 "Jessie" amd64/i386
# Debian 7 "Wheezy" amd64/i386
# Debian 6 "Squeeze" amd64/i386
# Ubuntu 18.04 LTS "Bionic Beaver" amd64/i386
# Ubuntu 16.04 LTS "Xenial Xerus" amd64/i386
# Ubuntu 14.04 LTS "Trusty Tahr" amd64/i386
# Ubuntu 12.04 LTS "Precise Pangolin" amd64/i386
# Ubuntu 10.04 LTS "Lucid Lynx" amd64/i386

echo "Starting Debian mirroring..."

# PID Control
PIDFILE=/var/run/debian-repo-update.pid
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

# Apt-mirror startup
# It's not working as expected so theres another cronjob running as apt-mirror
# user to do this update.
#su - apt-mirror -c /usr/bin/apt-mirror
#su - apt-mirror -c /var/spool/apt-mirror/clean.sh

# PXE fixup
DEBIAN="
        squeeze
        wheezy
        jessie
        stretch"

UBUNTU="
        lucid
        precise
        trusty
        xenial
        bionic"

ARCH="
        amd64
        i386"

for x in $DEBIAN ; do
        for y in $ARCH ; do
                wget --timestamping --no-directories ftp://ftp.br.debian.org/debian/dists/$x/main/installer-$y/current/images/netboot/debian-installer/$y/* -P /nfs/tftp/pxelinux/netinstall/debian/$x/$y &
        done
done

for x in $UBUNTU ; do
        for y in $ARCH ; do
                wget --timestamping --no-directories ftp://br.archive.ubuntu.com/ubuntu/dists/$x/main/installer-$y/current/images/netboot/ubuntu-installer/$y/* -P /nfs/tftp/pxelinux/netinstall/ubuntu/$x/$y &
        done
done

# Wait for all threads
wait

# Adding non-free drivers to Debian Installation
# Bugs no Wheezy... tem que mudar o laco do for
# Laço do for so vai ate dois para pegar os dois primeiros Debians: Squeeze
# Considerar remover essa merda visto que Debian esta sendo EOLd.

#FWTMP=/tmp/d-i_firmware
#mkdir -p $FWTMP/firmware
#cd $FWTMP

#wget --timestamping --no-directories http://cdimage.debian.org/cdimage/unofficial/non-free/firmware/squeeze/current/firmware.tar.gz
#tar -C firmware -zxf firmware.tar.gz
#pax -x sv4cpio -s'%firmware%/firmware%' -w firmware | gzip -c >firmware.cpio.gz

#for ((i = 0 ; i < 2 ; i++)) do
#       cd ${dir[i]}
#       [ -f initrd.gz.orig ] || cp -p initrd.gz initrd.gz.orig
#       mv initrd.gz initrd.gz.orig
#       cat initrd.gz.orig $FWTMP/firmware.cpio.gz > initrd.gz
#done

# Workarround for missing translation (i18n) files in Debian releases
# Download everything in parallel

#I18N_DIR="main contrib non-free"
#I18N_BASEPATH="/nfs/apt-mirror/mirror/ftp.br.debian.org/debian/dists"
#
#for x in $DEBIAN ; do
#       if [ $x = squeeze ] ; then
#               continue
#       fi
#
#       for y in $I18N_DIR ; do
#               wget --mirror ftp://ftp.br.debian.org/debian/dists/$x/$y/i18n/* -P $I18N_BASEPATH/$x/$y/i18n &
#               wget --mirror ftp://ftp.br.debian.org/debian/dists/$x-updates/$y/i18n/* -P $I18N_BASEPATH/$x-updates/$y/i18n &
#               wget --mirror ftp://ftp.br.debian.org/debian/dists/$x-backports/$y/i18n/* -P $I18N_BASEPATH/$x-backports/$y/i18n &
#       done
#done
#
# Wait for all threads
#wait

# Remove PID file
rm $PIDFILE
