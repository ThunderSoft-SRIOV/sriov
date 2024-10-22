#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -e

#----------------------------------      Global variable      --------------------------------------
GUEST_NUM=0
SSH_PORT=4444
WINRDP_PORT=3389
WINRM_PORT=5986

#----------------------------------         Functions         --------------------------------------
function show_help() {
    printf "$(basename "$0") [-h] [-n]\n"
    printf "Options:\n"
    printf "\t-h  show this help message\n"
    printf "\t-n  specify the num of guest VMs, eg. \"-n 2\"\n"
}

function parse_arg() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|-\?|--help)
                show_help
                exit
                ;;

            -n)
                GUEST_NUM=$2
                shift
                ;;

        esac
        shift
    done
}

#----------------------------------       Main Processes      --------------------------------------

parse_arg "$@" || exit -1

if [ $GUEST_NUM == 0 ]; then
    echo "Please specify the num of VMS with -n option!"
    exit
fi

for (( i = 1; i <= $GUEST_NUM; i++ )); do
    name=$(echo windows-vm$i)
    firmware=$(echo OVMF_VARS_windows$i.fd)
    disk=$(echo win$i.qcow2)
    ssh_port=$(expr $SSH_PORT + $i)
    winrdp_port=$(expr $WINRDP_PORT + $i)
    winrdm_port=$(expr $WINRM_PORT + $i)
    sudo ./scripts/setup_guest/win11/install_windows.sh -n $name -f $firmware -d $disk -p ssh=$ssh_port,winrdp=$winrdp_port,winrm=$winrdm_port &
    sleep 10
done
wait
