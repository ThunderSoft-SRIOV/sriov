#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -eE

#---------      Global variable     -------------------

#---------      Functions    -------------------



function check_network(){
    websites=("https://git.kernel.org/"
              "https://github.com/")

    for site in ${websites[@]}; do
        echo "Checking $site"
        wget --timeout=10 --tries=1 $site -nv --spider
        if [ $? -ne 0 ]; then
            echo "Error: Network issue, unable to access $site" | tee -a $WORK_DIR/$LOG_FILE
            echo "Error: Please check the internet access connection" | tee -a $WORK_DIR/$LOG_FILE
            echo "Solution to Network Problems One: Add a Proxy"
            echo "Proxy address depends on user environment. Usually by “export http_proxy=http://proxy_ip_url:proxy_port”"
            echo "Proxy address depends on user environment. Usually by “export https_proxy=https://proxy_ip_url:proxy_port”"
            echo "For example:"
            echo "export http_proxy=http://proxy-domain.com:912"
            echo "export https_proxy=http://proxy-domain.com:912"
            exit
        fi
    done
}


function sriov_firmware_download(){
	wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/snapshot/linux-firmware-20231211.tar.gz
	tar xzvf linux-firmware-20231211.tar.gz
	cd linux-firmware-20231211/i915
	# Copy firmware
	sudo cp adlp_guc_70.bin /lib/firmware/i915
	sudo cp tgl_guc_70.bin /lib/firmware/i915
	sudo cp tgl_huc.bin /lib/firmware/i915
	# Update initramfs
	sudo update-initramfs -u -k all
}




#-------------    main processes    -------------

check_network
sriov_firmware_download

echo "Done: \"$BASH_SOURCE $@\""
