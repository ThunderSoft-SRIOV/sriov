#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -e

#----------------------------------      Global variable      --------------------------------------
DEFAULT_VM_MEM=80
DEFAULT_NUM_CORES=2
DEFAULT_VM_NAME=win11
DEFAULT_DISK_SIZE=80

WIN_ISO_PATH=$PWD/scripts/setup_guest/win11
WIN_ISO=windows.iso
DEFAULT_OVMF_PATH=/usr/share/OVMF
DEFAULT_LIBVIRT_IMAGES_PATH=/var/lib/libvirt/images
WIN_IMAGE_NAME=$DEFAULT_VM_NAME.qcow2

#----------------------------------         Functions         --------------------------------------

function install_dep() {
    which virt-install > /dev/null || sudo apt install -y virtinst
    which virt-viewer > /dev/null || sudo apt install -y virt-viewer
}

function install_windows() {
    virt-install \
    --name=$DEFAULT_VM_NAME \
    --ram=$DEFAULT_VM_MEM \
    --vcpus=$DEFAULT_NUM_CORES \
    --cpu host \
    --machine q35 \
    --network network=default,model=virtio \
    --graphics vnc,listen=0.0.0.0,port=5905 \
    --cdrom "${WIN_ISO_PATH}/${WIN_ISO}" \
    --disk path="${DEFAULT_LIBVIRT_IMAGES_PATH}/${WIN_IMAGE_NAME}",format=qcow2,size=${DEFAULT_DISK_SIZE},bus=virtio,cache=none \
    --os-variant win11 \
    --boot loader="$DEFAULT_OVMF_PATH/OVMF_CODE_4M.ms.fd",loader.readonly=yes,loader.type=pflash,loader.secure=no,nvram.template=$DEFAULT_OVMF_PATH/OVMF_VARS_4M.fd \
    --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
    --pm suspend_to_mem.enabled=off,suspend_to_disk.enabled=on \
    --features smm.state=on \
    --noautoconsole \
    --wait=-1 || return 255
}

function show_help() {
    printf "$(basename "$0") [-h] [-m] [-c] [-n] [-d]\n"
    printf "Options:\n"
    printf "\t-h  show this help message\n"
    printf "\t-m  specify guest memory size, eg. \"-m 4G or -m 4096M\"\n"
    printf "\t-c  specify guest cpu number, eg. \"-c 4\"\n"
    printf "\t-n  specify guest vm name, eg. \"-n <guest_name>\"\n"
    printf "\t-d  specify guest virtual disk image, eg. \"-d /path/to/<guest_image>\"\n"
}

function parse_arg() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|-\?|--help)
                show_help
                exit
                ;;

            -m)
                DEFAULT_VM_MEM=$2
                shift
                ;;

            -c)
                DEFAULT_NUM_CORES=$2
                shift
                ;;

            -n)
                DEFAULT_VM_NAME=$2
                shift
                ;;

            -d)
                DEFAULT_DISK_SIZE=$2
                shift
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

#----------------------------------       Main Processes      --------------------------------------

parse_arg "$@" || exit -1

if [ ! -f $WIN_ISO_PATH/$WIN_ISO ]; then
	echo "Please copy windows iso image to $WIN_ISO_PATH"
	exit
fi

install_dep
install_windows || exit 255
