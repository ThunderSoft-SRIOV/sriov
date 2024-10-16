#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -x

#----------------------------------      Global variable      --------------------------------------
DEFAULT_OVMF_PATH=/usr/share/OVMF

#----------------------------------       Main Processes      --------------------------------------

cp $DEFAULT_OVMF_PATH/OVMF_VARS.fd ./OVMF_VARS_windows.fd
cp OVMF_VARS_windows.fd OVMF_VARS_windows2.fd
cp OVMF_VARS_windows.fd OVMF_VARS_windows3.fd
cp OVMF_VARS_windows.fd OVMF_VARS_windows4.fd

setup and use case:
# - number of guests
# - memory allocated
# - core allocated
# Propagate signal to children
trap 'trap " " SIGTERM; kill 0; wait' SIGINT SIGTERM

# Start Windows multi guests
echo "Starting Windows Guest1..."
sudo ./start_windows.sh -m 2G -c 2 -n windows-vm1 &

echo "Starting Windows Guest2..."
sudo ./start_windows.sh -m 2G -c 2 -n windows-vm2 -f OVMF_VARS_windows2.fd -d win2.qcow2 -p ssh=4445,winrdp=3390,winrm=5987 &

echo "Starting Windows Guest3..."
sudo ./start_windows.sh -m 2G -c 2 -n windows-vm3 -f OVMF_VARS_windows3.fd -d win3.qcow2 -p ssh=4446,winrdp=3391,winrm=5988 &

echo "Starting Windows Guest4..."
sudo ./start_windows.sh -m 2G -c 2 -n windows-vm4 -f OVMF_VARS_windows4.fd -d win4.qcow2 -p ssh=4447,winrdp=3392,winrm=5989 &
