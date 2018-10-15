#!/bin/sh
#
# Update Script para atualização dos RHEL, Clones e Repositórios
# Red Hat Enterprise Linux 7 amd64/SRPMS (+ RHN)
# Scientific Linux 5 amd64/i386/SRPMS
# Scientific Linux 6 amd64/i386/SRPMS
# Scientific Linux CERN 5 amd64/i386/SRPMS
# Scientific Linux CERN 6 amd64/i386/SRPMS
# CentOS 6 amd64/i386/SRPMS
# CentOS 7 amd64/SRPMS
# Extra Packages for Enterprise Linux 5/6/7 (EPEL)
# EMI UMD v1/v2 5/6 amd64
# OpenHPC
# Custom CC Repository
#
# Release History
# 3.0 Major release to support Red Hat Enterprise Linux
#     Red Hat Network Mirroring
#     Preliminar Security Erratas support in RHEL
#     Creation of custom CC repository with package signing
#     Inclusion of Zabbix official repo in CC repository
# 2.1 OpenHPC inclusion
# 2.0 Portability change to ditch /bin/bash in favor of /bin/sh
#     Multithreading
#     PID handling
#     Inclusion of SRPMS on all distros
#     Inclusion of EPEL 7
#     Code cleanup
# 1.6 Inclusion of CentOS 7
# 1.5 Removal of ia64 architecture from SL CERN 5x
# 1.4.1 Bugfix with initrd.gz updating in SL CERN and CentOS
# 1.4 Inclusion of SL CERN 5x/6x
# 1.3.1 Bugfix on pxeboot images copy of SL 5x/6x
# 1.3 First inclusion of CentOS
# 1.2.1 Fixed vmlinuz and initrd.gz not updating in the PXE environment, leading network boot to fail.
# 1.2 Added EMI UMD Repositories
# 1.1 Added EPEL Repositories
# 1.0 Initial Release

echo "Starting RHEL/Clones repositories  mirroring..."

# PID Control
PIDFILE=/var/run/rhel-repo-update.pid
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

# Critical Section
# Start the fetch of all repositories in parallel and mirror Red Hat Network

# Mirror RHN repositories
# Configuration file on /usr/local/etc/upstream_sync
# Check and replace RHN certificate on auth file
CERTNUMBER=`ls /etc/pki/entitlement | cut -f 1 -d - | grep -v pem`
sed "s/[0-9]\+/$CERTNUMBER/g" /usr/local/etc/upstream_sync/auth.conf
upstream_sync.py -v --root &

# Mirror clones and repositories
echo "Mirroring CentOS 7.x amd64:"
rsync -avkSH --delete --exclude=isos rsync://centos.ufes.br/centos/7 /nfs/repos/centos &

echo "Mirroring CentOS 6.x amd64/i386:"
rsync -avkSH --delete --exclude=isos rsync://centos.ufes.br/centos/6 /nfs/repos/centos &

echo "Mirroring Scientific Linux 6.x amd64/i386:"
rsync -avkSH --delete --exclude=archive --exclude=iso rsync://rsync.scientificlinux.org/scientific/6 /nfs/repos/scientific &

# Obsoleted and removed from upstream
echo "Mirroring Scientific Linux 5.x amd64/i386:"
rsync -avkSH --delete --exclude=sites --exclude=archive --exclude=iso rsync://rsync.scientificlinux.org/scientific/obsolete/5x /nfs/repos/scientific &

echo "Mirroring Scientific Linux CERN 6.x amd64/i386:"
rsync -avkSH --delete --exclude=iso rsync://linuxsoft.cern.ch/slc6x /nfs/repos/cern/slc6X &
rsync -avkSH --delete --exclude=iso rsync://linuxsoft.cern.ch/slc6X-updates /nfs/repos/cern/updates/slc6X &
rsync -avkSH --delete --exclude=iso rsync://linuxsoft.cern.ch/slc6X-extras /nfs/repos/cern/extras/slc6X &

echo "Mirroring Scientific Linux CERN 5.x amd64/i386:"
rsync -avkSH --delete --exclude=iso rsync://linuxsoft.cern.ch/slc5X /nfs/repos/cern/slc5X &
rsync -avkSH --delete --exclude=iso --exclude=ia64 rsync://linuxsoft.cern.ch/slc5X-updates /nfs/repos/cern/updates/slc5X &
rsync -avkSH --delete --exclude=iso rsync://linuxsoft.cern.ch/slc5X-extras /nfs/repos/cern/extras/slc5X &

# EPEL: Extra Packages for Enterprise Linux
echo "Fetching Base EPEL Directory:"
rsync -av --delete -d --exclude='*/' --exclude='*.rpm' rsync://download-ib01.fedoraproject.org/fedora-epel/ /nfs/repos/epel &
rm -f /nfs/repos/epel/4*

echo "Mirroring EPEL7 Repository:"
rsync -avkSH --delete --exclude debug --exclude=ppc64 --exclude=ppc64le rsync://download-ib01.fedoraproject.org/fedora-epel/7/ /nfs/repos/epel/7 &

echo "Mirroring EPEL6 Repository:"
rsync -avkSH --delete --exclude debug --exclude=ppc64 rsync://download-ib01.fedoraproject.org/fedora-epel/6/ /nfs/repos/epel/6 &

echo "Mirroring EPEL5 Repository:"
rsync -avkSH --delete --exclude debug --exclude=ppc rsync://download-ib01.fedoraproject.org/fedora-epel/5/ /nfs/repos/epel/5 &

# EGI-UMD
echo "Mirroring EGI-UMD1 5x RPM Repository:"
lftp -c 'open -e "mirror --delete --only-newer /sw/production/umd/1/sl5 /nfs/repos/egi/umd1-5x" http://repository.egi.eu' &

echo "Mirroring EGI-UMD2 5x RPM Repository:"
lftp -c 'open -e "mirror --delete --only-newer /sw/production/umd/2/sl5 /nfs/repos/egi/umd2-5x" http://repository.egi.eu' &

echo "Mirroring EGI-UMD2 6x RPM Repository:"
lftp -c 'open -e "mirror --delete --only-newer /sw/production/umd/2/sl6 /nfs/repos/egi/umd2-6x" http://repository.egi.eu' &

# OpenHPC (Only RHEL/CentOS repositories)
# Broken as 25/04/2017
#lftp -c 'open -e "mirror --delete --only-newer --include=".*\/CentOS.*" --exclude="Devel" --exclude="iso" --exclude="repocache" /OpenHPC: /nfs/repos/OpenHPC:" http://build.openhpc.community' &

# Wait threads to finish
wait

# Copy PXEBoot files to the tftp directory
cp /nfs/repos/centos/7/os/x86_64/images/pxeboot/* /nfs/tftp/pxelinux/netinstall/centos/7/amd64/
cp /nfs/repos/centos/6/os/x86_64/images/pxeboot/* /nfs/tftp/pxelinux/netinstall/centos/6/amd64/
cp /nfs/repos/centos/6/os/i386/images/pxeboot/* /nfs/tftp/pxelinux/netinstall/centos/6/i386/
cp /nfs/repos/scientific/6x/x86_64/os/images/pxeboot/* /nfs/tftp/pxelinux/netinstall/scientific/6x/amd64/
cp /nfs/repos/scientific/6x/i386/os/images/pxeboot/* /nfs/tftp/pxelinux/netinstall/scientific/6x/i386/
cp /nfs/repos/scientific/5x/x86_64/images/pxeboot/* /nfs/tftp/pxelinux/netinstall/scientific/5x/amd64/
cp /nfs/repos/scientific/5x/i386/images/pxeboot/* /nfs/tftp/pxelinux/netinstall/scientific/5x/i386
cp /nfs/repos/cern/slc6X/x86_64/images/pxeboot/* /nfs/tftp/pxelinux/netinstall/cern/6x/amd64/
cp /nfs/repos/cern/slc6X/i386/images/pxeboot/* /nfs/tftp/pxelinux/netinstall/cern/6x/i386/
cp /nfs/repos/cern/slc5X/x86_64/images/pxeboot/* /nfs/tftp/pxelinux/netinstall/cern/5x/amd64/
cp /nfs/repos/cern/slc5X/i386/images/pxeboot/* /nfs/tftp/pxelinux/netinstall/cern/5x/i386/

# Fetch security errata
# Better handling should be made here, this is just a kick fix to the problem.
YUMCACHE=/var/cache/yum/x86_64/7Server
LOCAL_REPODATA=/nfs/repos/rhel/server/7/7Server/x86_64/os/repodata

yum list-sec
rm -f $LOCAL_REPODATA/*-updateinfo.xml.gz
cp -v /var/cache/yum/x86_64/7Server/rhel-7-server-rpms/*-updateinfo.xml.gz $LOCAL_REPODATA
gunzip $LOCAL_REPODATA/*-updateinfo.xml.gz
mv $LOCAL_REPODATA/*-updateinfo.xml $LOCAL_REPODATA/updateinfo.xml
modifyrepo $LOCAL_REPODATA/updateinfo.xml $LOCAL_REPODATA
rm $LOCAL_REPODATA/updateinfo.xml

# Create local repositories
# Fetch rpms with reposync for custom and smaller repos
REPOPATH=/nfs/repos/cc/rpm
WORKERPATH=$REPOPATH/worker
reposync -c $WORKERPATH/reposync.conf -p $WORKERPATH/rpms --source --tempcache --downloadcomps --newest-only --delete

# Build merged tree, fix directories, sign packages with CC Key and at last
# create the repository metadata
for ARCH in x86_64 i386 src ; do
        for RELEASE in el5 el6 el7 ; do

                if [ $ARCH = "src" ] ; then
                        ARCHDIR=SRPMS
                else
                        ARCHDIR=$ARCH
                fi

                # Oh well another hack to fix i386/i*86 garbage
                if [ $ARCH = "i386" ] || [ $ARCH = "86." ] ; then
                        ARCH=86.
                        ARCHDIR=i386
                fi

                mkdir -p $REPOPATH/$RELEASE/$ARCHDIR ;
                find $WORKERPATH/rpms -type f -name "*$RELEASE*" -name "*$ARCH*" -exec ln -sf {} $REPOPATH/$RELEASE/$ARCHDIR \; ;
                LD_PRELOAD=$WORKERPATH/getpass.so rpmsign --key-id=F976644B --resign $REPOPATH/$RELEASE/$ARCHDIR/*.rpm ;
                createrepo --pretty --database --update -v --cachedir $REPOPATH/$RELEASE/$ARCHDIR/.cache $REPOPATH/$RELEASE/$ARCHDIR ;
        done ;
done

# Dirty hack to remove i386 ARCH from el7
rm -rf $REPOPATH/el7/i386

# Wait threads to finish
wait

# Remove PID file
rm $PIDFILE
