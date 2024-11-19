#!/bin/bash

# Copyright (c) 2024 Intel Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

#------------------------------------------------------      Global variable    ----------------------------------------------------------

set -x
FILE_PATH="$0"
SCRIPT_ABSOLUTE_PATH=$(readlink -f "$FILE_PATH")  
SCRIPT_DIR=${SCRIPT_ABSOLUTE_PATH%/*}
INSTALL_DIR=install_dir
SRIOV_PATH=${SCRIPT_ABSOLUTE_PATH%/*/*/*/*}


MEM_SIZE=4096
VM_IMAGE=./ubuntu.qcow2
NAME=ubuntu-vm
NUM_CORES=4
MAC_ADDR=DE:AD:BE:EF:B1:12


#------------------------------------------------------         Functions       ----------------------------------------------------------

if [ ! -d $SRIOV_PATH/$INSTALL_DIR/ ];then
  sudo mkdir $SRIOV_PATH/$INSTALL_DIR/
fi

if [ ! -f "/usr/share/OVMF/OVMF_CODE.fd" ];then
 	echo "not exists file "/usr/share/ovmf""
 	sudo apt update
	sudo apt -y -t bookworm-backports upgrade 
	sudo apt install -y -t bookworm-backports ovmf
 	exit
elif [ ! -f $SRIOV_PATH/$INSTALL_DIR/OVMF_CODE.fd ];then
	
	ln -sf /usr/share/OVMF/OVMF_CODE.fd  $SRIOV_PATH/$INSTALL_DIR/OVMF_CODE.fd
fi

if [ ! -f "/usr/share/OVMF/OVMF_VARS.fd" ];then
	echo "not exists file /usr/share/OVMF/OVMF_VARS.fd"
 	exit
elif [ ! -f $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_ubuntu.fd ];then
	cp /usr/share/OVMF/OVMF_VARS.fd  $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_ubuntu.fd
fi

if [ ! -f $SCRIPT_DIR/ubuntu.iso ];then
	echo "not exists file ${SCRIPT_DIR}/ubuntu.iso"
	exit
elif [ -f $SCRIPT_DIR/ubuntu.iso ];then
  cp -rf $SCRIPT_DIR/ubuntu.iso $SRIOV_PATH/$INSTALL_DIR/
fi

if [ ! -f $SRIOV_PATH/$INSTALL_DIR/ubuntu.qcow2 ];then
	qemu-img create -f qcow2 $SRIOV_PATH/$INSTALL_DIR/ubuntu.qcow2 60G
fi

cd $SRIOV_PATH/$INSTALL_DIR/

qemu-system-x86_64 \
        -m $MEM_SIZE \
        -enable-kvm \
        -cpu host \
        -name $NAME \
        -smp cores=$NUM_CORES,threads=2,sockets=1 \
        -device VGA,xres=1024,yres=768 \
        -drive file=./OVMF_CODE.fd,format=raw,if=pflash,unit=0,readonly=on \
        -drive file=./OVMF_VARS_ubuntu.fd,format=raw,if=pflash,unit=1 \
        -drive id=ubuntu_drive,if=virtio,file=$VM_IMAGE,format=qcow2,cache=none \
        -drive file=./ubuntu.iso,media=cdrom \
        -device e1000,netdev=net0,mac=$MAC_ADDR\
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -rtc base=localtime \
        -usb \
        -device usb-tablet
