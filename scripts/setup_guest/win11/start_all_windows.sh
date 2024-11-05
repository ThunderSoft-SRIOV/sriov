#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

# Sample script to launch multiple win guests
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


if [ ! -e  $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_win2.fd ] & [ ! -e $SRIOV_PATH/$INSTALL_DIR/win2.qcow2 ]; then
   echo "Copying win2.qcow2 file, Please be patient, it will take some time, file directory:${SRIOV_PATH}/${INSTALL_DIR}"
   cp -rf  $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_win.fd  $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_win2.fd
   cp -rf  $SRIOV_PATH/$INSTALL_DIR/win.qcow2         $SRIOV_PATH/$INSTALL_DIR/win2.qcow2
fi

if [ ! -e $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_win2.fd ] & [ ! -e $SRIOV_PATH/$INSTALL_DIR/win3.qcow2 ]; then
   echo "Copying win3.qcow2 file, Please be patient, it will take some time, file directory:${SRIOV_PATH}/${INSTALL_DIR}"
   cp -rf $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_win.fd  $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_win3.fd
   cp -rf $SRIOV_PATH/$INSTALL_DIR/win.qcow2         $SRIOV_PATH/$INSTALL_DIR/win3.qcow2
fi 

if [ ! -e $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_win2.fd ] & [ ! -e $SRIOV_PATH/$INSTALL_DIR/win4.qcow2 ]; then
   echo "Copying win4.qcow2 file, Please be patient, it will take some time, file directory:${SRIOV_PATH}/${INSTALL_DIR}"
   cp -rf $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_win.fd  $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_win4.fd
   cp -rf $SRIOV_PATH/$INSTALL_DIR/win.qcow2         $SRIOV_PATH/$INSTALL_DIR/win4.qcow2
fi 

echo " Done: Copy file completed"
echo " Starting VM"

cd $SCRIPT_DIR
trap 'trap " " SIGTERM; kill 0; wait' SIGINT SIGTERM
 Start win multi guests
echo "Starting win Guest1..."
sudo ./start_windows.sh -m 2G -c 2 -n win-vm1 &


echo "Starting win Guest2..."
sudo ./start_windows.sh -m 2G -c 2 -n win-vm2 -f $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_win2.fd -d $SRIOV_PATH/$INSTALL_DIR/win2.qcow2 -p ssh=2223 &


echo "Starting win Guest3..."
sudo ./start_windows.sh -m 2G -c 2  -n win-vm3 -f $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_win3.fd -d $SRIOV_PATH/$INSTALL_DIR/win3.qcow2 -p ssh=2224 &


echo "Starting win Guest4..."
sudo ./start_windows.sh -m 2G -c 2  -n win-vm4 -f $SRIOV_PATH/$INSTALL_DIR/OVMF_VARS_win4.fd -d $SRIOV_PATH/$INSTALL_DIR/win4.qcow2 -p ssh=2225 &
wait
