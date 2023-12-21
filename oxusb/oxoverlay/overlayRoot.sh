#!/bin/sh
#
#  By: oxdabit
#  Date: 18/01/2022
#  Mail: 0xdabit@gmail.com
#  Twitter: @0xDA_bit
#
#  Read-only SquashFS
#  Version 1.8
#  Script based in Read-only Root-FS for using overlayfs (v1.2)
#
#  Version History:
#  1.0: initial release
#  1.1: adopted new fstab style with PARTUUID. the script will now look for a /dev/xyz definiton first
#       (old raspbian), if that is not found, it will look for a partition with LABEL=rootfs, if that
#       is not found it look for a PARTUUID string in fstab for / and convert that to a device name
#       using the blkid command.
#  1.4: 0xDA_bit > Mount SFS File System inside the overlayFS structure
#  1.5: 0xDA_bit > Mount SFS firmware and platform in lower side
#  1.7: 0xDA_bit > Mount SFS as many files as there are in /lib/live/squashfs
#  1.8: 0xDA_bit > Mount SFS using <prefix-name_vX.Y.Z.sfs> file name structure
#  Update form 1.2 to 1.8 by OxDAbit
#
#  Created 2017 by Pascal Suter @ DALCO AG, Switzerland to work on Raspian as custom init script
#  (raspbian does not use an initramfs on boot)
#  Update 1.7 by OxDAbit@github
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see
#    <http://www.gnu.org/licenses/>.
#
#  Tested with Raspbian Buster lite
#
#  This script will mount the root filesystem read-only and overlay it with a temporary tempfs
#  which is read-write mounted. This is done using the overlayFS which is part of the linux kernel
#  since version 3.18.
#  when this script is in use, all changes made to anywhere in the root filesystem mount will be lost
#  upon reboot of the system. The SD card will only be accessed as read-only drive, which significantly
#  helps to prolong its life and prevent filesystem coruption in environments where the system is usually
#  not shut down properly
#

#
# Follow installation guide in: https://github.com/OxDAbit/overlayRoot.sh
#

fail(){
	echo -e "$1"
	/bin/bash
}

# load module
modprobe overlay
if [ $? -ne 0 ]; then
    fail "ERROR: missing overlay kernel module"
fi

# mount /proc
mount -t proc proc /proc
if [ $? -ne 0 ]; then
    fail "ERROR: could not mount proc"
fi

# create a writable fs to then create our mountpoints
mount -t tmpfs inittemp /mnt
if [ $? -ne 0 ]; then
    fail "ERROR: could not create a temporary filesystem to mount the base filesystems for overlayfs"
fi

mkdir /mnt/lower
mkdir /mnt/rw

mount -t tmpfs root-rw /mnt/rw
if [ $? -ne 0 ]; then
    fail "ERROR: could not create tempfs for upper filesystem"
fi

mkdir /mnt/rw/upper
mkdir /mnt/rw/work
mkdir /mnt/newroot
mkdir /mnt/squashed

# mount root filesystem readonly
rootDev=`awk '$2 == "/" {print $1}' /etc/fstab`
rootMountOpt=`awk '$2 == "/" {print $4}' /etc/fstab`
rootFsType=`awk '$2 == "/" {print $3}' /etc/fstab`

echo "check if we can locate the root device based on fstab"

blkid $rootDev
if [ $? -gt 0 ]; then
    echo "no success, try if a filesystem with label 'rootfs' is avaialble"
    rootDevFstab=$rootDev
    rootDev=`blkid -L "rootfs"`
    if [ $? -gt 0 ]; then
        echo "no luck either, try to further parse fstab's root device definition"
        echo "try if fstab contains a PARTUUID definition"
        echo "$rootDevFstab" | grep 'PARTUUID=\(.*\)-\([0-9]\{2\}\)'
        if [ $? -gt 0 ]; then
	    fail "could not find a root filesystem device in fstab. Make sure that fstab contains a device definition or a PARTUUID entry for / or that the root filesystem has a label 'rootfs' assigned to it"
        fi
        device=""
        partition=""
        eval `echo "$rootDevFstab" | sed -e 's/PARTUUID=\(.*\)-\([0-9]\{2\}\)/device=\1;partition=\2/'`
        rootDev=`blkid -t "PTUUID=$device" | awk -F : '{print $1}'`p$(($partition))
        blkid $rootDev
        if [ $? -gt 0 ]; then
	    fail "The PARTUUID entry in fstab could not be converted into a valid device name. Make sure that fstab contains a device definition or a PARTUUID entry for / or that the root filesystem has a label 'rootfs' assigned to it"
        fi
    fi
fi

mount -t ${rootFsType} -o ${rootMountOpt},ro ${rootDev} /mnt/lower
if [ $? -ne 0 ]; then
    fail "ERROR: could not ro-mount original root partition"
fi

# Load complete file system path to use in overlay mount process
fspath=""
files=""

for f in `ls /mnt/lower/lib/live/squashfs`;
do
	echo "\n-------------- New SFS package -----------------"

	# Working with packages (Ex: 01-firmware_v0.4.0.sfs)
	# Load package  extension (Ex: sfs)
	ext="${f##*.}"
	if [ $ext = "sfs" ]; then
		# Check if version is in package name
		version=`echo $f | grep "_v"`
		if [ -z $version ]; then
			echo "\n[WARNING]\tArchivo SFS pero no dispone de versionado"
		else
			# Load package version (Ex: v0.4.0)
			ver=`echo $version | awk -F '_' '{print $2}'`
			ver="${ver%.*}"

			# Load package name (Ex: firmware)
			name="${f%.*}"
			name=`echo $name | awk -F '-' '{print $2}'`
			name="${name%_*}"

			# Load path name (Ex: /mnt/squashed/firmware)
			s="/mnt/squashed/"$name

			# Load file names in array
			if [ -n "$fspath" ]; then
				fspath="$fspath:$s"
				files="$files:$name"
			else
				fspath=$s
				files=$name
			fi

			# Create folder for each file
			mkdir /mnt/squashed/$name

			# Mount file in its path
			mount -o loop -t squashfs /mnt/lower/lib/live/squashfs/${f} /mnt/squashed/${name}
		fi
	fi
	echo "------------------------------------------------"
done

# Mount Overlay with squashs file system
mount -t overlay -o lowerdir=${fspath}:/mnt/lower,upperdir=/mnt/rw/upper,workdir=/mnt/rw/work overlayfs-root /mnt/newroot
if [ $? -ne 0 ]; then
    fail "ERROR: could not mount overlayFS"
fi

# remove root mount from fstab (this is already a non-permanent modification)
grep -v "$rootDev" /mnt/lower/etc/fstab > /mnt/newroot/etc/fstab

echo "#the original root mount has been removed by overlayRoot.sh" >> /mnt/newroot/etc/fstab
echo "#this is only a temporary modification, the original fstab" >> /mnt/newroot/etc/fstab
echo "#stored on the disk can be found in /ro/etc/fstab" >> /mnt/newroot/etc/fstab

# change to the new overlay root
cd /mnt/newroot

pivot_root . mnt
exec chroot . sh -c "$(cat <<END

# Move SFS mounts to the new root
/bin/sh /sbin/overlaySFS.sh -f $files

# Move RO and RW mounts to the new root
mount --move /mnt/mnt/lower/ /lib/live/mounted/ro
if [ $? -ne 0 ]; then
    echo "ERROR: could not move ro-root into newroot"
    /bin/bash
else
    echo "RO folder succesfully mounted"
fi

mount --move /mnt/mnt/rw /lib/live/mounted/rw
if [ $? -ne 0 ]; then
    echo "ERROR: could not move tempfs rw mount into newroot"
    /bin/bash
else
    echo "RW folder succesfully mounted"
fi

# unmount unneeded mounts so we can unmout the old readonly root
umount /mnt/mnt
umount /mnt/proc
umount /mnt/dev
umount /mnt

/bin/sh /sbin/overlaySFS.sh -u $files

# continue with regular init
exec /sbin/init

END
)"
