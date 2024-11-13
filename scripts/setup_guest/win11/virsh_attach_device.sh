#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -e

#----------------------------------      Global variable      --------------------------------------
WIN_DOMAIN_NAME="win11"

AVAIL_PCI_BUS=""

#----------------------------------         Functions         --------------------------------------
function setup_sriov() {
    # Detect total number of VFs
    totalvfs=$(</sys/bus/pci/devices/0000\:00\:02.0/sriov_totalvfs)

    if [ $totalvfs -eq 0 ]; then
        echo "Error: total number of supported VFs is 0"
        exit
    fi
    echo "Total VFs $totalvfs"

    # Detect number of VFs
    numvfs=$(</sys/bus/pci/devices/0000\:00\:02.0/sriov_numvfs)

    # Enable VFs only when 0
    if [ $numvfs -eq 0 ]; then
        # Setup VFIO
        echo "Enabling $totalvfs VFs"
        local vendor=$(cat /sys/bus/pci/devices/0000:00:02.0/iommu_group/devices/0000:00:02.0/vendor)
        local device=$(cat /sys/bus/pci/devices/0000:00:02.0/iommu_group/devices/0000:00:02.0/device)
        sudo sh -c "modprobe i2c-algo-bit"
        sudo sh -c "sudo modprobe video"
        sudo sh -c "echo '0' | sudo tee -a /sys/bus/pci/devices/0000\:00\:02.0/sriov_drivers_autoprobe > /dev/null"
        sudo sh -c "echo $totalvfs | sudo tee -a /sys/class/drm/card0/device/sriov_numvfs > /dev/null"
        sudo sh -c "echo '1' | sudo tee -a /sys/bus/pci/devices/0000\:00\:02.0/sriov_drivers_autoprobe > /dev/null"
        sudo sh -c "sudo modprobe vfio-pci"
        sudo sh -c "echo '$vendor $device' | sudo tee -a /sys/bus/pci/drivers/vfio-pci/new_id > /dev/null"
    fi

    # Detect number of VFs
    numvfs=$(</sys/bus/pci/devices/0000\:00\:02.0/sriov_numvfs)

    # Detect first available VF
    for (( avail=1; avail<=numvfs; avail++ )); do
        is_enabled=$(</sys/bus/pci/devices/0000:00:02.$avail/enable)
        if [ $is_enabled = 0 ]; then
            VF_USED=$avail
            echo "Using VF $avail"
            break;
        fi
    done

    if [ $VF_USED -eq 0 ]; then
        echo "Error: no VF available"
        exit
    fi

    AVAIL_PCI_BUS=0000:00:02.$avail
}

function attach_pci() {
    PCI_DOMAIN=$(echo "$AVAIL_PCI_BUS" | cut -d':' -f1)
    PCI_BUS=$(echo "$AVAIL_PCI_BUS" | cut -d':' -f2)
    PCI_SLOT=$(echo "$AVAIL_PCI_BUS" | cut -d':' -f3 | cut -d '.' -f1)
    PCI_FUNC=$(echo "$AVAIL_PCI_BUS" | cut -d':' -f3 | cut -d '.' -f2)

    pci_iommu=$(sudo virsh nodedev-dumpxml pci_"${PCI_DOMAIN}"_"${PCI_BUS}"_"${PCI_SLOT}"_"${PCI_FUNC}" | grep address)
    mapfile pci_array <<< "$pci_iommu"

    for pci in "${pci_array[@]}"; do
        local pci_bus
        pci_bus=$(echo "$pci" | sed "s/.*domain='0x\([^']\+\)'.*bus='0x\([^']\+\)'.*slot='0x\([^']\+\)'.*function='0x\([^']\+\)'.*/\1:\2:\3.\4/")
        if [ $pci_bus = $AVAIL_PCI_BUS ]; then
            break
        fi
    done

    cat<<EOF | tee pci.xml
<hostdev mode="subsystem" type="pci" managed="yes">
  <source>
  $pci
  </source>
</hostdev>
EOF
    sudo virsh attach-device $WIN_DOMAIN_NAME pci.xml --persistent
}

function show_help() {
    printf "$(basename "$0") [-h] [-n]\n"
    printf "Options:\n"
    printf "\t-h  show this help message\n"
    printf "\t-n  specify guest vm name, eg. \"-n <guest_name>\"\n"
}

function parse_arg() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|-\?|--help)
                show_help
                exit
                ;;

            -n)
                WIN_DOMAIN_NAME=$2
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

setup_sriov
attach_pci
