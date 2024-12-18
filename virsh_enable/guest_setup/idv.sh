#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -e

#----------------------------------      Global variable      --------------------------------------
WORK_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

IDV_USER=$USER
VM_IMAGE_DIR="/home/$IDV_USER/sriov/install_dir"

declare -A VM_DOMAIN=(
    ["ubuntu"]="ubuntu_sriov.xml"
    ["windows11"]="windows11_sriov_ovmf.xml"
)

declare -A VM_IMAGE=(
    ["ubuntu"]="ubuntu.qcow2"
    ["windows11"]="win.qcow2"
)

declare -A VM_OVMF=(
    ["ubuntu"]="OVMF_VARS_ubuntu.fd"
    ["windows11"]="OVMF_VARS_windows.fd"
)

#----------------------------------         Functions         --------------------------------------
function get_vm_config()  {
    local domain=$1

    VM_NAME=$domain
    VM_OVMF_VARS="$VM_IMAGE_DIR/${VM_OVMF[$domain]}"
    VM_IMAGE_PATH="$VM_IMAGE_DIR/${VM_IMAGE[$domain]}"
    VM_OVMF_CODE="$VM_IMAGE_DIR/OVMF_CODE.fd"

    TEMPLATE_FILE="$WORK_DIR/../template.xml"
    VM_CONFIG_FILE="$WORK_DIR/../${VM_DOMAIN[$domain]}"
}

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

    if [[ ! "${!VM_DOMAIN[*]}" =~ $1 ]]; then
        echo "Domain $1 is not supported."
        show_help
        exit 255
    fi

    get_vm_config $1
    gen_vm_xml
}

function show_help() {
    printf "$(basename "$0") [option]\n"
    printf "Options:\n"
    printf "\t-h  show this help message\n"
    printf "\tinit\t[vm_name]\t initialize virtual machine, eg: init windows11\n"
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
