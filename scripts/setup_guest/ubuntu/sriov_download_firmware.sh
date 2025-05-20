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
        if ! wget --timeout=10 --tries=1 $site -nv --spider
        then
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
    
    # Download firmware
	git clone --branch 20231211 --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
	# Copy firmware
	sudo cp linux-firmware/i915/adlp_guc_70.bin /lib/firmware/i915
    sudo cp linux-firmware/i915/tgl_guc_70.bin /lib/firmware/i915
    sudo cp linux-firmware/i915/tgl_huc.bin /lib/firmware/i915
	# Update initramfs
	sudo update-initramfs -u -k all
}




#-------------    main processes    -------------

check_network
sriov_firmware_download

echo "Done: \"$BASH_SOURCE $@\""
