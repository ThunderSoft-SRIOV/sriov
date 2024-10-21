#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -x

#----------------------------------      Global variable      --------------------------------------
DEFAULT_MEM_SIZE=4096
MAC_ADDR=DE:AD:BE:EF:B1:11

INSTALL_DIR=$PWD/install_dir
VM_IMAGE=$INSTALL_DIR/win.qcow2
DEFAULT_VM_NAME=windows-vm
DEFAULT_NUM_CORES=4
TPM_DIR=$INSTALL_DIR/win.qcow2.d
GUEST_SWTPM="-chardev socket,id=chrtpm,path=$TPM_DIR/vtpm0/swtpm-sock -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0"
WIN_ISO_PATH=$PWD/scripts/setup_guest/win11
WIN_ISO=windows.iso

#----------------------------------       Main Processes      --------------------------------------

if [ ! -f $WIN_ISO_PATH/$WIN_ISO ]; then
	echo "Please copy windows iso image to $WIN_ISO_PATH"
	exit
fi

if [ ! -f $INSTALL_DIR ]; then
	sudo mkdir -p $INSTALL_DIR
fi
cd $INSTALL_DIR

if [ ! -f "/usr/share/OVMF/OVMF_CODE.fd" ]; then
 	echo "not found file "/usr/share/OVMF""
 	sudo apt update
	sudo apt -y -t bookworm-backports upgrade 
	sudo apt install -y -t bookworm-backports omvf
 	exit
elif [ ! -f './OVMF_CODE.fd' ]; then
	ln -sf /usr/share/OVMF/OVMF_CODE.fd ./OVMF_CODE.fd
fi

if [ ! -f "/usr/share/OVMF/OVMF_VARS.fd" ]; then
	echo "not found file "/usr/share/OVMF/OVMF_VARS.fd""
 	exit
elif [ ! -f './OVMF_VARS_windows.fd' ]; then
	cp /usr/share/OVMF/OVMF_VARS.fd ./OVMF_VARS_windows.fd
fi

if [ ! -f $INSTALL_DIR/win.qcow2 ]; then
	sudo qemu-img create -f qcow2 ./win.qcow2 80G
fi

# Start swtpm
mkdir -p $TPM_DIR/vtpm0
swtpm socket --tpmstate dir=$TPM_DIR/vtpm0 --tpm2 --ctrl type=unixio,path=$TPM_DIR/vtpm0/swtpm-sock --daemon

# Start guest
sudo qemu-system-x86_64 \
	-m $DEFAULT_MEM_SIZE \
	-enable-kvm \
	-cpu host \
	-name $DEFAULT_VM_NAME \
	-smp cores=$DEFAULT_NUM_CORES,threads=2,sockets=1 \
	-drive file=./OVMF_CODE.fd,format=raw,if=pflash,unit=0,readonly=on \
	-drive file=./OVMF_VARS_windows.fd,format=raw,if=pflash,unit=1 \
	-drive file=$VM_IMAGE,format=qcow2,cache=none \
	-drive file=$WIN_ISO_PATH/$WIN_ISO,media=cdrom \
	-device e1000,netdev=net0,mac=$MAC_ADDR\
	-netdev user,id=net0,restrict=y,hostfwd=tcp::4444-:22 \
	-rtc base=localtime \
	-usb \
	-device usb-tablet \
    -device VGA,xres=1024,yres=768 \
    -machine q35 \
    -$GUEST_SWTPM
