#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -e

#----------------------------------      Global variable      --------------------------------------
IDVUSER=$USER

VM_IMAGE_DIR="/home/$IDVUSER/sriov/install_dir"
VM_IMAGE_PATH="$VM_IMAGE_DIR/win.qcow2"

VM_NAME=""
VM_OVMF_CODE="$VM_IMAGE_DIR/OVMF_CODE.fd"
VM_OVMF_VARS="$VM_IMAGE_DIR/OVMF_VARS_windows.fd"

TEMPLATE_FILE="/home/$IDVUSER/sriov/virsh_enable/template.xml"
VM_CONFIG_FILE="/home/$IDVUSER/sriov/virsh_enable/windows11_sriov_ovmf.xml"

#----------------------------------         Functions         --------------------------------------
function gen_vm_xml() {
    sed -e "s;%VM_NAME%;${VM_NAME};" \
        -e "s;%VM_OVMF_CODE%;${VM_OVMF_CODE};" \
        -e "s;%VM_OVMF_VARS%;${VM_OVMF_VARS};" \
        -e "s;%VM_IMAGE%;${VM_IMAGE_PATH};" \
        ${TEMPLATE_FILE} >$VM_CONFIG_FILE
}

function init() {
    if [ -z $1 ]; then
        show_help
        exit -1
    fi
    VM_NAME=$1

    gen_vm_xml
}

function show_help() {
    printf "$(basename "$0") [option]\n"
    printf "Options:\n"
    printf "\t-h  show this help message\n"
    printf "\tinit\t[all|vm_name]\t initialize virtual machine, eg: init all\n"
}

function parse_arg() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|-\?|--help)
                show_help
                exit
                ;;

            init)
                init $2
                exit
                ;;

            start)
                exit
                ;;

            -?*)
                echo "Error: Invalid option $1"
                show_help
                return -1
                ;;

            *)
                echo "unknown option: $1"
                return -1
                ;;
        esac
        shift
    done
}

#----------------------------------       Main Processes      --------------------------------------

parse_arg "$@" || exit -1
