#!/bin/bash

# Copyright (c) 2024 Intel Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -x


if [ ! -f "/usr/share/OVMF/OVMF_CODE.fd" ];then
 	echo "not exists file "/usr/share/ovmf""
 	sudo apt update
	sudo apt -y -t bookworm-backports upgrade 
	sudo apt install -y -t bookworm-backports omvf
 	exit
elif [ ! -f './OVMF_CODE.fd' ];then
	
	ln -sf /usr/share/OVMF/OVMF_CODE.fd  ./OVMF_CODE.fd
fi


if [ ! -f "/usr/share/OVMF/OVMF_VARS.fd" ];then
	echo "not exists file "/usr/share/OVMF/OVMF_VARS.fd""
 	exit
elif [ ! -f './OVMF_VARS_ubuntu.fd' ];then
	cp /usr/share/OVMF/OVMF_VARS.fd  ./OVMF_VARS_ubuntu.fd
fi

if [ ! -f "./ubuntu.iso" ];then
	echo "not exists file ./ubuntu.iso"
	exit
elif [ ! -f './ubuntu.iso' ] | [ ! -f './ubuntu.qcow2' ];then
	#ln -sf ./ubuntu-22.04-desktop-amd64+intel-iot.iso   ./ubuntu.iso
	qemu-img create -f qcow2 ./ubuntu.qcow2 200G
fi


MEM_SIZE=4096
VM_IMAGE=./ubuntu.qcow2
NAME=ubuntu-vm
NUM_CORES=4
MAC_ADDR=DE:AD:BE:EF:B1:12



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
