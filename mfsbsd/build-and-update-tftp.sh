#!/bin/sh

# Debug
debug=true

# Define Architectures (Spaces delimited)
architectures="amd64 i386"

# Define tools
pkg_static_location=`whereis -bq pkg-static | cut -f 1 -d " "`

# Check for mounted images and try to eject them all using mdconfig
for md in `mdconfig -l`
do

	if ($debug) then
		echo DEVICE FOUND: $md
	fi

	umount /dev/$md
	mdconfig -d -u $md

done

# Remove any existing .img files
rm *.img

# Main loop
# It fetches the architectures and then try to find all supported FreeBSD releases
# within a given architecture
for arch in $architectures
do

	if ($debug) then 
		echo $arch RELEASES: 
	fi

	for iso in `find /nfs/repos/FreeBSD/releases/ISO-IMAGES -name "*RELEASE*" -name "*disc1*" -name "*$arch*" ! -name "*.xz" ! -name "*uefi*"`
	do

		if ($debug) then 
			echo FOUND: $iso
		fi
		release=`echo $iso | xargs -n 1 basename | awk -F - '{print $2 "-" $3}'`

		mdconfig -a -t vnode -f $iso -u 1
		mount_cd9660 /dev/md1 /mnt/mfsbsd

		make clean
		make ARCH=$arch BASE=/mnt/mfsbsd/usr/freebsd-dist RELEASE=$release CFGDIR=conf/$release PKG_STATIC=$pkg_static_location MFSROOT_MAXSIZE=100m

		umount /mnt/mfsbsd
		mdconfig -d -u 1

	done
done

# Move all images to the FreeBSD tftp folder
if ($debug) then 
	echo Moving images to FreeBSD tftp folder.
fi
mv -v *.img /nfs/tftp/pxelinux/netinstall/freebsd/

echo Done

