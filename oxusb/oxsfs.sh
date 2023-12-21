#!/bin/bash

#-------------------------------------------------------#
#                       oxsfs.sh                        #
#                                                       #
# Purpose:      oxsfs raspbian init configuration       #
# Version:      v0.1.7                                  #
# Created:      21/12/2023                              #
#                                                       #
# Author:       David Alvarez Medina aka OxDA_bit       #
# Mail:         0xdabit@gmail.com                       #
# Twitter:      @0xDA_bit                               #
# Github:       OxDAbit                                 #
#-------------------------------------------------------#

declare partition_name="/oxdata"
declare wifi_ssid="SSID"
declare wifi_pswd="PSWD"
declare wifi_iface="wlan0"
declare keyboard="es"
declare language="es_ES.UTF-8"
declare user="oxuser"
declare default_hostname="oxdevice"

function get_disk_information ()
{
    # /dev/sda2
    root_part_dev=$(findmnt / -o source -n)
    # sda2
    root_part_name=$(echo "$root_part_dev" | cut -d "/" -f 3)
    # sda
    root_dev_name=$(echo /sys/block/*/"${root_part_name}" | cut -d "/" -f 4)
    # /dev/sda
    root_dev="/dev/${root_dev_name}"
    # BYT;
    # /dev/da:125045424:ci:512:512:mdo:NGFF 224 2 64GB SSD:;
    # 1:8192:532479:524288:fat32::lba;
    # 2:532480:62256472:61723993:ext4::;
    # 3:62256473:125045423:62788951:ext4::;
    partition_table=$(parted -m "$root_dev" unit s print | tr -d 's')
    # 3
    last_part_num=$(echo "$partition_table" | tail -n 1 | cut -d ":" -f 1)
    # 2
    root_part_num=$(cat "/sys/block/${root_dev_name}/${root_part_name}/partition")
    # 9730496b
    disk_uuid=$(fdisk -l "$root_dev" | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')
    # 3
    partition_part_num=$((root_part_num + 1))
    # 9730496b-03
    partition_uuid="$disk_uuid-0$partition_part_num"
    # 532479
    boot_end=`fdisk -l | grep "/dev/sda1" | awk '{print $3}'`
    # 532480
    root_begin=$((boot_end + 1))
    # 125045424
    root_dev_size=$(cat "/sys/block/${root_dev_name}/size")
    # 124512945
    partition_size=$((root_dev_size - boot_end))
    # 62256472
    root_end=$((partition_size/2))
    # 62256473
    partition_begin=$((root_end + 1))
    # 125045423
    partition_end=$((root_dev_size - 1))
    # 9730496b
    disk_uuid=$(fdisk -l "$root_dev" | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')
    # 9730496b-02
    root_uuid=$disk_uuid"-02"

    # SD Card create a partition "mmcblk" so add "p" to create third partition (Ex: mmcblk0p3)
    if [[ $root_dev = /dev/mmcblk* ]]
    then
        partition_dev_name=$root_dev"p"$partition_part_num
    else
        partition_dev_name=$root_dev$partition_part_num
    fi

    echo "[INFO]	Disk variables loaded"
}

function manage_disk ()
{
    if [ $last_part_num -eq $root_part_num ]; then
        # Expand root partition
        parted -s -m /dev/sda u s resizepart 2 124506456 > /dev/null 2>&1
        echo "[INFO]	Root partition resized"

        # Create third partition (/oxdata)
        sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $root_dev
n               	# Create new partition
p               	# Set primary partition
$partition_part_num     # Set third partition
$partition_begin        # Set begin sector
$partition_end          # Set end sectir
w               	# Write changes
q               	# Exit fdisk
EOF
        echo "[INFO]	Data partition created $partition_dev_name"

        # Set format for /oxdata partition
        mkdir /oxdata
        mkfs -t ext4 -N 128 -m 0 -L $partition_name $partition_dev_name
        sed -i '/#/d' /etc/fstab
        echo "PARTUUID=$partition_uuid	$partition_name		ext4	defaults,noatime	0	1" >> /etc/fstab
        echo "[INFO]	New partition $partition_name created and formated"

        # Forced mounted partition /oxdata
        mount -a

        echo "[INFO]	Parition $partition_name is mounted"
        echo "[INFO]	Creating $partition_name folder structure"

        # Create custom folders inside /oxdata partition
        mkdir -p /oxdata/content/system_base
        mkdir -p /oxdata/logs
        mkdir -p /oxdata/SystemUpdate
        mkdir -p /oxdata/temp

        # Resize root partition
        echo "[INFO]	Resizing $root_part_dev partition"
        resize2fs $root_part_dev
        if [ $? -eq 0 ]; then
            echo "[INFO]	Root partition is extended"
        else
            echo "[ERROR]	Error during $root_part_dev resizing"
        fi
    else
        echo "[WARNING]	Disk have more than 2 partitions. Script is shutdown..."
        exit 0
    fi
}

function user_configuration ()
{
    # Config keyboard layout
    localectl set-x11-keymap $keyboard

    # Config language
    sed -i "s/^\s*LANG=\S*/LANG=$language/" /etc/default/locale
    echo "[INFO]	Language configurated <$language>"

    # Enable SSH connection
    cmd='s/^[#\s]*PasswordAuthentication\s\+\S\+$/PasswordAuthentication yes/'
    sed -i "$cmd" /etc/ssh/sshd_config
    systemctl -q enable ssh
    echo "[INFO]	SSH comunication enable"

    # Copy .bashrc pi configuration to sudo user
    sudo cp "/home/$user/.bashrc" /root/
    echo "[INFO]	.bashrc file copy to user path folder"
}

function wifi_configuration ()
{
    # Encrypt WiFi credentials
    wpa=`wpa_passphrase "$wifi_ssid" <<< "$wifi_pswd"`

    # Remove newlines
    wpa=${wpa//$'\n'/}

    # Extract encrypt password
    pwd=$(echo $wpa | awk -F 'psk=' '{print $3}')

    # Remove last character '}'
    pwd=${pwd::-1}

    # Config WiFi
    /usr/lib/raspberrypi-sys-mods/imager_custom set_wlan $wifi_ssid $pwd
    echo "[INFO]	WiFi configuration"

    # Restart service
    systemctl restart NetworkManager
    echo "[INFO]	NetworkManager restarted"
}

function sfs_configuration ()
{
    echo "[INFO]	Updating repo"
    # Update repo
    apt-get update
    apt-get upgrade -y

    # Install packages
    apt-get install squashfs-tools -y
    apt-get install tree
    apt-get install python3-pip -y
    apt-get install jq -y
    echo "[INFO]	Packages installed"

    # Disable SWAP
    dphys-swapfile swapoff
    dphys-swapfile uninstall
    update-rc.d dphys-swapfile remove
    systemctl stop dphys-swapfile.service
    systemctl disable dphys-swapfile.service
    echo "[INFO]	SWAP disabled"

    # Create folder structure
    mkdir -p /lib/live/mounted/ro
    mkdir -p /lib/live/mounted/rw
    mkdir -p /lib/live/mounted/squashed
    mkdir -p /lib/live/squashfs

    # Copy SFS files
    cp -r /media/oxusb/oxsfs/* /lib/live/squashfs
    cp -r /media/oxusb/oxoverlay/overlayRoot.sh /sbin/
    cp -r /media/oxusb/oxoverlay/overlaySFS.sh /sbin

    # Copy content file
    cp -r /media/oxusb/content/oxcpu.conf /oxdata/content/sys

    # Create news cmdline files
    touch /boot/cmdline-no_overlay.txt
    echo "console=serial0,115200 console=tty1 root=PARTUUID=$root_uuid rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait logo.nologo" >> /boot/cmdline-no_overlay.txt
    touch /boot/cmdline-overlay.txt
    echo "console=serial0,115200 console=tty1 root=PARTUUID=$root_uuid rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait init=/sbin/overlayRoot.sh logo.nologo" >> /boot/cmdline-overlay.txt
    echo "[INFO]	cmdline files created"

    # Enable SFS boot
    #cp /boot/cmdline-overlay.txt /boot/cmdline.txt
    #echo "[INFO]	SFS boot enabled"

    # Make script executable
    chmod +x /sbin/overlayRoot.sh
    chmod +x /sbin/overlaySFS.sh
    echo "[INFO]	oxSFS structure created"
}

function network_configuration ()
{
    # Update /etc/hosts file changing "raspberrypi" hostname to "ox-000."
    sed -i 's#raspberrypi.*#'$default_hostname'#' /etc/hosts

    # Update /etc/hostname adding "ox-000"
    echo "$default_hostname" > /etc/hostname

    # Reload hsotname
    /bin/hostname -F /etc/hostname
}

function clean_and_close ()
{
    # Clean time
    apt autoremove -y
    apt-get clean
    rm -rf /tmp/*
    history -c
    echo "[INFO]	Clean process end"

    # Reboot
    echo "[INFO]	Rebooting system..."
    sleep 3
    reboot
    exit 0
}

function main ()
{
    if [ $1 ]; then
        # Config WiFi client
        wifi_configuration
    fi

    # Load disk information
    get_disk_information

    # Expand root partition and create data partition
    manage_disk

    # Add new user, config language, keyboard and SSH connection
    user_configuration

    # Create folder structure and copy files
    sfs_configuration

    # Config default hostname
    network_configuration

    # Cleaning process
    clean_and_close
}

if [ $1 ]; then
    if [ $1 == "wifi" ]; then
        echo "[INFO]	Scripts starts with WiFi configuration"
        main $1
    else
        echo "[WARNING]	The selected option is not one of the options expected by the script"
    fi
else
    echo "[INFO]	Scripts starts without WiFi configuration"
    main
fi
