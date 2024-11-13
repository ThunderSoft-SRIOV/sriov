#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -e

#----------------------------------      Global variable      --------------------------------------
WIN_DOMAIN_NAME=win11
WIN_IMAGE_NAME=$WIN_DOMAIN_NAME.qcow2
WIN_INSTALLER_ISO=windows.iso
WIN_INSTALLER_ISO_PATH=$PWD/scripts/setup_guest/win11
WIN_VIRTIO_ISO=virtio-win-0.1.221.iso

DEFAULT_VM_MEM=4096
DEFAULT_NUM_CORES=4
DEFAULT_DISK_SIZE=60

DEFAULT_OVMF_PATH=/usr/share/OVMF
DEFAULT_LIBVIRT_IMAGES_PATH=/var/lib/libvirt/images

#----------------------------------         Functions         --------------------------------------

function install_dep() {
    which virt-install > /dev/null || sudo apt install -y virtinst
    which virt-viewer > /dev/null || sudo apt install -y virt-viewer
}

function start_default_net() {
    local active=$(sudo virsh net-info default | grep "Active" | awk '{gsub(/ /,"")}1' | cut -d':' -f2)
    if [ $active = "no" ]; then
        sudo virsh net-start default
    fi
}

function install_windows() {
    virt-install \
    --name $WIN_DOMAIN_NAME \
    --ram $DEFAULT_VM_MEM \
    --vcpus $DEFAULT_NUM_CORES \
    --cpu host \
    --machine q35 \
    --network network=default,model=virtio \
    --graphics vnc,listen=0.0.0.0,port=5905 \
    --cdrom "${WIN_INSTALLER_ISO_PATH}/${WIN_INSTALLER_ISO}" \
    --disk "/tmp/${WIN_VIRTIO_ISO}",device=cdrom \
    --disk "${DEFAULT_LIBVIRT_IMAGES_PATH}/${WIN_IMAGE_NAME}",format=qcow2,size=${DEFAULT_DISK_SIZE},bus=virtio,cache=none \
    --os-variant win11 \
    --boot loader="$DEFAULT_OVMF_PATH/OVMF_CODE_4M.ms.fd",loader.readonly=yes,loader.type=pflash,loader.secure=no,nvram.template=$DEFAULT_OVMF_PATH/OVMF_VARS_4M.fd \
    --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
    --pm suspend_to_mem.enabled=off,suspend_to_disk.enabled=on \
    --features smm.state=on \
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
                WIN_DOMAIN_NAME=$2
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

if [ ! -f $WIN_INSTALLER_ISO_PATH/$WIN_INSTALLER_ISO ]; then
	echo "Please copy $WIN_INSTALLER_ISO to $WIN_INSTALLER_ISO_PATH"
	exit
fi

if [ ! -f /tmp/$WIN_VIRTIO_ISO ]; then
	echo "Please copy $WIN_VIRTIO_ISO to /tmp"
	exit
fi

install_dep
start_default_net
install_windows || exit 255
