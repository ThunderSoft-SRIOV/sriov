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

#----------------------------------      Global variable      --------------------------------------

FILE_PATH="$0"
SCRIPT_ABSOLUTE_PATH=$(readlink -f "$FILE_PATH")  
SCRIPT_DIR=${SCRIPT_ABSOLUTE_PATH%/*} 
SRIOV_PATH=${SCRIPT_ABSOLUTE_PATH%/*/*/*/*}
INSTALL_DIR=$SRIOV_PATH/install_dir

#----------------------------------       Main Processes      --------------------------------------

if [ ! -e $INSTALL_DIR/OVMF_VARS_windows2.fd ] & [ ! -e $INSTALL_DIR/win2.qcow2 ]; then
    echo "Copying win2.qcow2 file, Please be patient, it will take some time, file directory:${INSTALL_DIR}"
    cp -rf  $INSTALL_DIR/OVMF_VARS_windows.fd  $INSTALL_DIR/OVMF_VARS_windows2.fd
    cp -rf  $INSTALL_DIR/win.qcow2 $INSTALL_DIR/win2.qcow2
fi

if [ ! -e $INSTALL_DIR/OVMF_VARS_windows3.fd ] & [ ! -e $INSTALL_DIR/win3.qcow2 ]; then
    echo "Copying win3.qcow2 file, Please be patient, it will take some time, file directory:${INSTALL_DIR}"
    cp -rf $INSTALL_DIR/OVMF_VARS_windows.fd  $INSTALL_DIR/OVMF_VARS_windows3.fd
    cp -rf $INSTALL_DIR/win.qcow2 $INSTALL_DIR/win3.qcow2
fi 

if [ ! -e $INSTALL_DIR/OVMF_VARS_windows4.fd ] & [ ! -e $INSTALL_DIR/win4.qcow2 ]; then
    echo "Copying win4.qcow2 file, Please be patient, it will take some time, file directory:${INSTALL_DIR}"
    cp -rf $INSTALL_DIR/OVMF_VARS_windows.fd  $INSTALL_DIR/OVMF_VARS_windows4.fd
    cp -rf $INSTALL_DIR/win.qcow2 $INSTALL_DIR/win4.qcow2
fi 

echo " Done: Copy file completed"
echo " Starting VM"

trap 'trap " " SIGTERM; kill 0; wait' SIGINT SIGTERM

# Start Windows multi guests
echo "Starting Windows Guest1..."
sudo $SCRIPT_DIR/start_windows.sh -m 2G -c 2 -n windows-vm1 &

echo "Starting Windows Guest2..."
sudo $SCRIPT_DIR/start_windows.sh -m 2G -c 2 -n windows-vm2 -f OVMF_VARS_windows2.fd -d win2.qcow2 -p ssh=4445,winrdp=3390,winrm=5987 &

echo "Starting Windows Guest3..."
sudo $SCRIPT_DIR/start_windows.sh -m 2G -c 2 -n windows-vm3 -f OVMF_VARS_windows3.fd -d win3.qcow2 -p ssh=4446,winrdp=3391,winrm=5988 &

echo "Starting Windows Guest4..."
sudo $SCRIPT_DIR/start_windows.sh -m 2G -c 2 -n windows-vm4 -f OVMF_VARS_windows4.fd -d win4.qcow2 -p ssh=4447,winrdp=3392,winrm=5989 &

wait
