#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -e

#----------------------------------      Global variable      --------------------------------------
DEFAULT_VM_MEM=80
DEFAULT_NUM_CORES=2
DEFAULT_VM_NAME=ubuntu
DEFAULT_DISK_SIZE=80

DEFAULT_OVMF_PATH=/usr/share/OVMF
WIN_INSTALLER_ISO=$WORK_DIR/ubuntu-22.04-desktop-amd64+intel-iot.iso
DEFAULT_LIBVIRT_IMAGES_PATH=/var/lib/libvirt/images
WIN_IMAGE_NAME=$DEFAULT_VM_NAME.qcow2

#----------------------------------         Functions         --------------------------------------



if [ ! -f "/usr/share/OVMF/OVMF_CODE.fd" ];then
 	echo "not exists file "/usr/share/ovmf""
 	sudo apt update
	sudo apt -y -t bookworm-backports upgrade 
	sudo apt install -y -t bookworm-backports omvf
 	exit
#elif [ ! -f './OVMF_CODE.fd' ];then
	
#	ln -sf /usr/share/OVMF/OVMF_CODE.fd  ./OVMF_CODE.fd
#fi


#if [ ! -f "/usr/share/OVMF/OVMF_VARS.fd" ];then
#	echo "not exists file "/usr/share/OVMF/OVMF_VARS.fd""
# 	exit
#elif [ ! -f './OVMF_VARS_ubuntu.fd' ];then
#	cp /usr/share/OVMF/OVMF_VARS.fd  ./OVMF_VARS_ubuntu.fd
#fi

if [ ! -f "./ubuntu-22.04-desktop-amd64+intel-iot.iso" ];then
	echo "not exists file "./ubuntu-22.04-desktop-amd64+intel-iot.iso""
	exit
elif [ ! -f './ubuntu-22.04-desktop-amd64+intel-iot.iso' ] | [ ! -f './ubuntu.qcow2' ];then
	ln -sf ./ubuntu-22.04-desktop-amd64+intel-iot.iso   ./ubuntu.iso
	qemu-img create -f qcow2 ./ubuntu.qcow2 200G
fi


function install_dep() {
  which virt-install > /dev/null || sudo apt install -y virtinst
  which virt-viewer > /dev/null || sudo apt install -y virt-viewer
}

function install_ubuntu() {
    virt-install \
    --name=$DEFAULT_VM_NAME \
    --ram=$DEFAULT_VM_MEM \
    --vcpus=$DEFAULT_NUM_CORES \
    --cpu host \
    --machine q35 \
    --network network=default,model=virtio \
    --graphics vnc,listen=0.0.0.0,port=5905 \
    --cdrom "${WIN_INSTALLER_ISO}" \
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
                GUEST_CPU_NUM=$2
                shift
                ;;

            -n)
                GUEST_NAME=$2
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

install_dep
install_ubuntu || exit 255
