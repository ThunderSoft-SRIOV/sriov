#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

# Sample script to launch multiple Ubuntu guests
# Remember to customise the launch commands according to HW 
#setup and use case:
# - number of guests
# - memory allocated
# - core allocated
# Propagate signal to children

FILE_PATH="$0"
SCRIPT_ABSOLUTE_PATH=$(readlink -f "$FILE_PATH")  
SCRIPT_DIR=$(dirname "$FILE_PATH") 
INSTALL_DIR=install_dir
SRIOV_PATH=${SCRIPT_ABSOLUTE_PATH%/*/*/*/*}


if [ ! -e  $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_ubuntu2.fd ] & [ ! -e $SRIOV_PATH/$INSTALL_DIR/ubuntu2.qcow2 ];then
   cp -rf  $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_ubuntu.fd  $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_ubuntu2.fd
   cp -rf  $SRIOV_PATH/$INSTALL_DIR/ubuntu.qcow2         $SRIOV_PATH/$INSTALL_DIR/ubuntu2.qcow2
fi 


if [ ! -e $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_ubuntu2.fd ] & [ ! -e $SRIOV_PATH/$INSTALL_DIR/ubuntu3.qcow2 ];then
   cp -rf $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_ubuntu.fd  $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_ubuntu3.fd
   cp -rf $SRIOV_PATH/$INSTALL_DIR/ubuntu.qcow2         $SRIOV_PATH/$INSTALL_DIR/ubuntu3.qcow2
fi 


if [ ! -e $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_ubuntu2.fd ] & [ ! -e $SRIOV_PATH/$INSTALL_DIR/ubuntu4.qcow2 ];then
   cp -rf $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_ubuntu.fd  $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_ubuntu4.fd
   cp -rf $SRIOV_PATH/$INSTALL_DIR/ubuntu.qcow2         $SRIOV_PATH/$INSTALL_DIR/ubuntu4.qcow2
fi 



#trap 'trap " " SIGTERM; kill 0; wait' SIGINT SIGTERM
# Start Ubuntu multi guests
#echo "Starting Ubuntu Guest1..."
#sudo ./start_ubuntu.sh -m 4G -c 2 --display full-screen,connectors.0=DP-1 -n ubuntu-vm1 &


#echo "Starting Ubuntu Guest2..."
#sudo ./start_ubuntu.sh -m 4G -c 2 --display full-screen,connectors.0=DP-3 -n ubuntu-vm2 -f OVMF_VARS_ubuntu2.fd -d ubuntu2.qcow2 -p ssh=2223 &


#echo "Starting Ubuntu Guest3..."
#sudo ./start_ubuntu.sh -m 4G -c 2 --display full-screen,connectors.0=HDMI-1 -n ubuntu-vm3 -f OVMF_VARS_ubuntu3.fd -d ubuntu3.qcow2 -p ssh=2224 &


#echo "Starting Ubuntu Guest4..."
#sudo ./start_ubuntu.sh -m 4G -c 2 --display full-screen,connectors.0=HDMI-2 -n ubuntu-vm4 -f OVMF_VARS_ubuntu4.fd -d ubuntu4.qcow2 -p ssh=2225 &
#wait

cd $SCRIPT_DIR
trap 'trap " " SIGTERM; kill 0; wait' SIGINT SIGTERM
 Start Ubuntu multi guests
echo "Starting Ubuntu Guest1..."
sudo ./start_ubuntu.sh -m 2G -c 2 -n ubuntu-vm1 &


echo "Starting Ubuntu Guest2..."
sudo ./start_ubuntu.sh -m 2G -c 2 -n ubuntu-vm2 -f OVMF_VARS_ubuntu2.fd -d $SRIOV_PATH/$INSTALL_DIR/ubuntu2.qcow2 -p ssh=2223 &


echo "Starting Ubuntu Guest3..."
sudo ./start_ubuntu.sh -m 2G -c 2  -n ubuntu-vm3 -f OVMF_VARS_ubuntu3.fd -d $SRIOV_PATH/$INSTALL_DIR/ubuntu3.qcow2 -p ssh=2224 &


echo "Starting Ubuntu Guest4..."
sudo ./start_ubuntu.sh -m 2G -c 2  -n ubuntu-vm4 -f OVMF_VARS_ubuntu4.fd -d $SRIOV_PATH/$INSTALL_DIR/ubuntu4.qcow2 -p ssh=2225 &
wait
