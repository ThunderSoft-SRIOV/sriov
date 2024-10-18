#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -eE

#---------      Global variable     -------------------
WORK_DIR=$(pwd)
GUEST_SETUP=1
USE_INSTALL_FILES=1

#---------      Functions    -------------------


function setup_guest_pwr_ctrl(){
    if [ -f $WORK_DIR/sriov_setup_pwr_ctrl.sh ]; then
        # mark script as a guest side script
        sed -i "s/#GUEST_SCRIPT=1/GUEST_SCRIPT=1/g" $WORK_DIR/sriov_setup_pwr_ctrl.sh

        # make a copy for guest startup
        sudo cp $WORK_DIR/sriov_setup_pwr_ctrl.sh /usr/local/bin/
        sudo chmod 744 /usr/local/bin/sriov_setup_pwr_ctrl.sh

        # create startup service
        sudo echo '            [Unit]
            After=swap.target

            [Service]
            ExecStart=/usr/local/bin/sriov_setup_pwr_ctrl.sh

            [Install]
            WantedBy=default.target' > /etc/systemd/system/swap-space-update.service
        sudo chmod 664 /etc/systemd/system/swap-space-update.service

        # enable startup service
        sudo systemctl daemon-reload
        sudo systemctl enable swap-space-update.service

    else
        echo "Error: sriov_setup_pwr_ctrl.sh file is missing"
        exit
    fi
}

function show_help() {
    printf "$(basename "$0") [-h] [--bsp]\n"
    printf "Options:\n"
    printf "\t-h      show this help message\n"
    printf "\t--bsp   configure guest for Ubuntu BSP.\n"
}

function parse_arg() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|-\?|--help)
                show_help
                exit
                ;;

            --bsp)
                IS_BSP=1
                ;;

            -?*)
                echo "Error: Invalid option: $1"
                show_help
                return -1
                ;;
            *)
                echo "Error: Unknown option: $1"
                return -1
                ;;
        esac
        shift
    done
}


#-------------    main processes    -------------

parse_arg "$@" || exit -1

setup_guest_pwr_ctrl
source $WORK_DIR/sriov_setup_ubuntu.sh
