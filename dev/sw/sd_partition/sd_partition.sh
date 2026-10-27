#  (c) Copyright 2024 Xilinx, Inc. All rights reserved.
#
#  This file contains confidential and proprietary information
#  of Advanced Micro Devices, Inc. and is protected under U.S. and
#  international copyright and other intellectual property
#  laws.
#
#  DISCLAIMER
#  This disclaimer is not a license and does not grant any
#  rights to the materials distributed herewith. Except as
#  otherwise provided in a valid license issued to you by
#  AMD, and to the maximum extent permitted by applicable
#  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
#  WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
#  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
#  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
#  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
#  (2) AMD shall not be liable (whether in contract or tort,
#  including negligence, or under any other theory of
#  liability) for any loss or damage of any kind or nature
#  related to, arising under or in connection with these
#  materials, including for any direct, or any indirect,
#  special, incidental, or consequential loss or damage
#  (including loss of data, profits, goodwill, or any type of
#  loss or damage suffered as a result of any action brought
#  by a third party) even if such damage or loss was
#  reasonably foreseeable or AMD had been advised of the
#  possibility of the same.
#
#  CRITICAL APPLICATIONS
#  AMD products are not designed or intended to be fail-
#  safe, or for use in any application requiring fail-safe
#  performance, such as life-support or safety devices or
#  systems, Class III medical devices, nuclear facilities,
#  applications related to the deployment of airbags, or any
#  other applications that could lead to death, personal
#  injury, or severe property or environmental damage
#  (individually and collectively, "Critical
#  Applications"). Customer assumes the sole risk and
#  liability of any use of AMD products in Critical
#  Applications, subject only to applicable laws and
#  regulations governing limitations on product liability.
#
#  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
#  PART OF THIS FILE AT ALL TIMES.

# SD Card Partitioning
#
# This is example script to create SD-Card with correct partitions for system boot on board
#
# CAUTION: this will delete current contents of SD-Card. It must be run using JTAG-Boot so that we are not using the rootfs 
# to run the operating system.
#
# The script uses fdisk to create the following partitions:
# * FAT32 Partition for system boot (2G)
# * EXT4  Partition for Root Filesystem using remaining space
# It operates by piping menu commands to fdisk so it can be dependent on ordering of menu options for fdisk
#
# After creating partitions with fdisk, Script then formats filesystems using mkfs.vfat , mkfs.ext4
#

# unmount SD Card
sudo umount /dev/*mmcblk0*

# run fdisk
delete_p1="d\n1\n"
delete_p2="d\n2\n"
new_p1="n\np\n1\n8192\n+2G\n"
new_p2="n\np\n2\n4202496\n\n"
type_p1="t\n1\nb\n"
type_p2="t\n2\n83\n"
write_table="w\n"
fdisk_cmd="$delete_p1$delete_p2$new_p1$new_p2$type_p1$type_p2$write_table"
echo -e $fdisk_cmd | sudo fdisk /dev/mmcblk0

# make filesystems
sudo mkfs.vfat -F32 /dev/mmcblk0p1
sudo mkfs.ext4 -F   /dev/mmcblk0p2

# mount filesystems
sudo mount /dev/mmcblk0p1 /run/media/mmcblk0p1/
sudo mount /dev/mmcblk0p2 /run/media/mmcblk0p2/

# finish
echo "SD Formatting completed"

