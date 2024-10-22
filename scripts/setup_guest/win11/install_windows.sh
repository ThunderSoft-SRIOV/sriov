#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -e

#----------------------------------      Global variable      --------------------------------------
INSTALL_DIR=$PWD/install_dir
GUEST_IMAGE_FILE=$INSTALL_DIR/win.qcow2
GUEST_FIRMWARE_FILE=$INSTALL_DIR/OVMF_VARS_windows.fd
TPM_DIR=$INSTALL_DIR/win.qcow2.d
WIN_ISO_PATH=$PWD/scripts/setup_guest/win11
WIN_ISO=windows.iso

EMULATOR_PATH=$(which qemu-system-x86_64)
GUEST_NAME="-name windows-vm"
GUEST_MEM="-m 4G"
GUEST_CPU_NUM="-smp cores=4,threads=2,sockets=1"
GUEST_DISK="-drive file=$INSTALL_DIR/win.qcow2,id=windows_disk,format=qcow2,cache=none"
GUEST_FIRMWARE="\
 -drive file=$INSTALL_DIR/OVMF_CODE.fd,format=raw,if=pflash,unit=0,readonly=on \
 -drive file=$INSTALL_DIR/OVMF_VARS_windows.fd,format=raw,if=pflash,unit=1"
GUEST_VGA_DEV="-device VGA,xres=1024,yres=768"
GUEST_MAC_ADDR="DE:AD:BE:EF:B1:14"
GUEST_NET="-device e1000,netdev=net0,mac=$GUEST_MAC_ADDR\
 -netdev user,id=net0,hostfwd=tcp::4444-:22,hostfwd=tcp::5986-:5986,hostfwd=tcp::3389-:3389"
GUEST_SWTPM="-chardev socket,id=chrtpm,path=$TPM_DIR/vtpm0/swtpm-sock -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0"
GUEST_STATIC_OPTION="\
 -machine q35 \
 -enable-kvm \
 -k en-us \
 -cpu host \
 -rtc base=localtime"

GUEST_USB_DEV="\
	-usb \
	-device usb-tablet"

GUEST_ISO_FILE="-drive file=$WIN_ISO_PATH/$WIN_ISO,media=cdrom"

#----------------------------------         Functions         --------------------------------------

function set_name() {
    GUEST_NAME="-name $1"
}

function set_mem() {
    GUEST_MEM="-m $1"
}

function set_cpu() {
    GUEST_CPU_NUM="-smp cores=$1,threads=2,sockets=1"
}

function set_disk() {
    GUEST_DISK="-drive file=$INSTALL_DIR/$1,id=windows_disk1,format=qcow2,cache=none"
    GUEST_IMAGE_FILE=$INSTALL_DIR/$1
    set_swtpm $1
}

function set_swtpm() {
    TPM_DIR=$INSTALL_DIR/$1.d
    GUEST_SWTPM="-chardev socket,id=chrtpm,path=$TPM_DIR/vtpm0/swtpm-sock -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0"
}

function set_firmware_path() {
    GUEST_FIRMWARE="\
        -drive file=$INSTALL_DIR/OVMF_CODE.fd,format=raw,if=pflash,unit=0,readonly=on \
        -drive file=$INSTALL_DIR/$1,format=raw,if=pflash,unit=1"
    GUEST_FIRMWARE_FILE=$INSTALL_DIR/$1
}

function setup_swtpm() {
    mkdir -p $TPM_DIR/vtpm0
    swtpm socket --tpmstate dir=$TPM_DIR/vtpm0 --tpm2 --ctrl type=unixio,path=$TPM_DIR/vtpm0/swtpm-sock --daemon
}

function set_fwd_port() {
    OIFS=$IFS IFS=',' port_arr=($1) IFS=$OIFS
    for e in "${port_arr[@]}"; do
        if [[ $e =~ ^ssh= ]]; then
            GUEST_NET="${GUEST_NET/4444-:22/${e#*=}-:22}"
        elif [[ $e =~ ^winrdp= ]]; then
            GUEST_NET="${GUEST_NET/3389-:3389/${e#*=}-:3389}"
        elif [[ $e =~ ^winrm= ]]; then
            GUEST_NET="${GUEST_NET/5986-:5986/${e#*=}-:5986}"
        else
            echo "E: Forward port, Invalid parameter"
            return -1;
        fi
    done
}

function install_guest() {
    local EXE_CMD="$EMULATOR_PATH \
                   $GUEST_MEM \
                   $GUEST_CPU_NUM \
                   $GUEST_NAME \
    "

    # Expand new introduced device here.
    EXE_CMD+="$GUEST_DISK \
              $GUEST_VGA_DEV \
              $GUEST_FIRMWARE \
			  $GUEST_NET \
			  $GUEST_SWTPM \
			  $GUEST_STATIC_OPTION \
			  $GUEST_USB_DEV \
			  $GUEST_ISO_FILE \
    "

    echo $EXE_CMD
    eval $EXE_CMD
}

function show_help() {
    printf "$(basename "$0") [-h] [-m] [-c] [-n] [-d] [-f] [-p]\n"
    printf "Options:\n"
    printf "\t-h  show this help message\n"
    printf "\t-m  specify guest memory size, eg. \"-m 4G or -m 4096M\"\n"
    printf "\t-c  specify guest cpu number, eg. \"-c 4\"\n"
    printf "\t-n  specify guest vm name, eg. \"-n <guest_name>\"\n"
    printf "\t-d  specify guest virtual disk image, eg. \"-d /path/to/<guest_image>\"\n"
	printf "\t-f  specify guest firmware OVMF variable image, eg. \"-d /path/to/<ovmf_vars.fd>\"\n"
    printf "\t-p  specify host forward ports, current support ssh,winrdp,winrm, eg. \"-p ssh=4444,winrdp=5555,winrm=6666\"\n"
}

function parse_arg() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|-\?|--help)
                show_help
                exit
                ;;

            -m)
                set_mem $2
                shift
                ;;

            -c)
                set_cpu $2
                shift
                ;;

            -n)
                set_name $2
                shift
                ;;

            -d)
                set_disk $2
                shift
                ;;

            -f)
                set_firmware_path $2
                shift
                ;;

            -p)
                set_fwd_port $2
                shift
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

if [ ! -f $INSTALL_DIR ]; then
	sudo mkdir -p $INSTALL_DIR
fi

if [ ! -f "/usr/share/OVMF/OVMF_CODE.fd" ]; then
 	echo "not found file "/usr/share/OVMF""
 	sudo apt update
	sudo apt -y -t bookworm-backports upgrade 
	sudo apt install -y -t bookworm-backports omvf
 	exit
elif [ ! -f './OVMF_CODE.fd' ]; then
	ln -sf /usr/share/OVMF/OVMF_CODE.fd $INSTALL_DIR/OVMF_CODE.fd
fi

if [ ! -f "/usr/share/OVMF/OVMF_VARS.fd" ]; then
	echo "not found file "/usr/share/OVMF/OVMF_VARS.fd""
 	exit
elif [ ! -f $GUEST_FIRMWARE_FILE ]; then
	cp /usr/share/OVMF/OVMF_VARS.fd $GUEST_FIRMWARE_FILE
fi

if [ ! -f $GUEST_IMAGE_FILE ]; then
	sudo qemu-img create -f qcow2 $GUEST_IMAGE_FILE 60G
fi

setup_swtpm
install_guest

echo "Done: \"$(realpath $0) $@\""
