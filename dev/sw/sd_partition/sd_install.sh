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

# SD Installation
#
# Script copies boot products and root filesystem to appropriate area on SD-Card
#
# Recommended use is to scp install files to local directory on board (such as /home/petalinux directory) including this script. e.g.
#
# e.g. scp -r ./sd_products petalinux@149.199.131.169:/home/petalinux
#
# On board, cd to local directory and then run this script.
#

# copy boot products
sudo cp ./BOOT.BIN /run/media/mmcblk0p1 
sudo cp ./image.ub /run/media/mmcblk0p1 
sudo cp ./boot.scr /run/media/mmcblk0p1 

# untar to rootfs (assumes rootfs is not being used - so JTAG boot)
sudo rm -rf /run/media/mmcblk0p2/*
sudo tar xzvf rootfs.tar.gz -C /run/media/mmcblk0p2

# sync with SD-Card
sudo sync

# sudo-reboot
