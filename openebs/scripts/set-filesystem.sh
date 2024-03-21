#!/bin/bash

<<'MULTILINE-COMMENT'
    Requirments: none
    Description: Script for set Storage OpenEBS for Kubernetes clusters
    Author: Marcos Silvestrini
    Date: 23/08/2023
MULTILINE-COMMENT

# Set language/locale and encoding
export LANG=C

# Clear display
clear

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

echo "SET STORAGE FOR OPENEBS..."

# Variables
WORK_DIR="/home/ubuntu/setup-openebs"
PARTITION_NUMBER=1
VG_NAME="vg_openebs"
LV_NAME="lv_openebs"
FS_MOUNT="/dev/$VG_NAME/$LV_NAME"
FS_FOLDER="/var/k8s/storage/openebs"

# Set workdir
echo "Create workdir: $WORK_DIR"
if [ ! -d "$WORK_DIR" ]; then
    mkdir -p "$WORK_DIR"
fi
if [ -d "$WORK_DIR" ]; then
    cd "$WORK_DIR" || return
else
    echo "Working dir $WORK_DIR not present!!!"
    exit 1
fi

# Set Storage (device /dev/vdb)

## Find free disk for OpenEBS
echo "Find disk free for OpenEBS..."

### Get a list of all disks except vda
disks=$(lsblk -o NAME -n | grep -E "^vd[^a]")

### Iterate through each disk
for disk in $disks; do
    echo "Check disk: /dev/$disk"
    # Check if the disk is mounted
    if mount | grep -q "/dev/$disk"; then
        echo "  Disk is in use by another aplication!!! Skipping"
    else
        DISK_OPENEBS="/dev/$disk"
        PARTITION="$DISK_OPENEBS"1 
        echo "  Disk not Not Mounted. This is disk for OpenEBS Storage"        
        # Check if the partition file exists
        echo "Check partition: $PARTITION"
        if [ -e "$PARTITION" ]; then
        echo "  $PARTITION exists...Disk is in use by another aplication!!! Skipping"
        else
            echo "  $PARTITION does not exist.This is partition for OpenEBS Storage"
            break
        fi         
    fi 
    
    echo
done

# Check if the partition is mounted
echo "Check if the partition "/dev/mapper/$VG_NAME-$LV_NAME" is mounted"
if mount | grep -q "/dev/mapper/$VG_NAME-$LV_NAME"; then
    echo "    Status: Mounted"
    echo "    Mount Point: $(mount | grep "/dev/mapper/$VG_NAME-$LV_NAME" | awk '{print $3}')"
    exit 1
else
    echo "    Status: Not Mounted"
fi

# Partition disk with LVM

## Start the parted command
parted "$DISK_OPENEBS" --script mklabel gpt

## Create a partition with hex code 8e (Linux LVM)
parted "$DISK_OPENEBS" --script mkpart primary 0% 100%
parted "$DISK_OPENEBS" --script set 1 lvm on

## Print the partition table to verify
parted "$DISK_OPENEBS" --script print

# create pv
echo "Create pv for OpenEBS Storage"
pvcreate "$DISK_OPENEBS$PARTITION_NUMBER"

# create vg
echo "Create vg $VG_NAME for OpenEBS Storage"
vgcreate "$VG_NAME" "$DISK_OPENEBS$PARTITION_NUMBER"

# create lv
echo "Create lv $LV_NAME for OpenEBS Storage"
lvcreate -l +100%FREE -n "$LV_NAME" "$VG_NAME"

# format lv with filesystem xfs
echo "Create filesystem xfs"
mkfs.xfs "$FS_MOUNT"
xfs_admin -L "OpenEBS" "$FS_MOUNT"

# Set mountpoint in /etc/fstab
echo "Set mountpoint $FS_MOUNT in /etc/fstab"
#-rw-r--r-- 1 root root 652 Mar 24 10:25 /etc/fstab

## Create directory
mkdir -p $FS_FOLDER

## Backup fstab file
VM=$(hostname)
if [ ! -f "fstab_${VM}_backup" ]; then
    cp /etc/fstab "fstab_${VM}_backup"
fi

## Add mountpoint to /etc/fstab
if grep -qi "openebs" /etc/fstab; then
    echo "Mountpoint $FS_MOUNT already exists in /etc/fstab"
else
    echo "Add mountpoint $FS_MOUNT to /etc/fstab"
    echo "#OpenEBS Storage - BEGIN" >>/etc/fstab
    echo "$FS_MOUNT    $FS_FOLDER xfs     defaults        0 0" >>/etc/fstab
    echo "#OpenEBS Storage - END" >>/etc/fstab
fi
systemctl daemon-reload

# Mount OpenEBS Filesystem
echo "Mount OpenEBS Filesystem $FS_MOUNT--->$FS_FOLDER"
umount $FS_FOLDER >/dev/null 2>&1
mount $FS_FOLDER
