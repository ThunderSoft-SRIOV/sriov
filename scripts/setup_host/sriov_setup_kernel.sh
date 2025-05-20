#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -eE

#----------------------------------      Global variable      --------------------------------------
WORK_DIR=$(pwd)
LOG_FILE="sriov_setup_kernel.log"
PACKAGES_DIR=$WORK_DIR/packages

reboot_required=0

IS_BSP=0
USE_INSTALL_FILES=0

#----------------------------------         Functions         --------------------------------------

function sriov_add_source_list() {
    # Add repository and update
    sudo echo 'deb http://deb.debian.org/debian bookworm-backports main non-free-firmware' | sudo tee -a /etc/apt/sources.list.d/debian_sriov.list
    sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D' /etc/apt/sources.list.d/debian_sriov.list
    sudo apt update
    sudo apt -t bookworm-backports upgrade 
}

function sriov_install_packages() {
    # List of required packages
    PACKAGES="git curl fakeroot build-essential ncurses-dev xz-utils libssl-dev \
    bc flex libelf-dev bison rsync kmod cpio unzip lz4 ninja-build pkg-config \
    libglib2.0-dev libpixman-1-dev libspice-protocol-dev libspice-server-dev \
    libusbredirparser-dev python3-venv libglib2.0-dev libpixman-1-dev \
    libspice-server1 libgtk-3-dev libusbredirparser-dev libusb-1.0-0-dev \
    libslirp-dev swtpm libgbm-dev quilt debhelper"

    if [[ $USE_INSTALL_FILES -ne 1 ]]; then
        # Download packages
        sudo apt-get install -y --download-only -t bookworm-backports --reinstall ${PACKAGES}

        # Make a copy of packages
        del_existing_folder $PACKAGES_DIR
        mkdir -p $PACKAGES_DIR
        sudo cp /var/cache/apt/archives/*.deb $PACKAGES_DIR
    fi

    # Install packages
    sudo apt-get install -y -t bookworm-backports ${PACKAGES}
    cd $WORK_DIR
}

function sriov_install_firmware() {
    # Create temporary folder
    del_existing_folder $WORK_DIR/firmware_install
    mkdir $WORK_DIR/firmware_install
    cd $WORK_DIR/firmware_install

    # Download firmware
    git clone --branch 20231211 --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git

    # Copy firmware
    sudo cp linux-firmware/i915/adlp_guc_70.bin /lib/firmware/i915
    sudo cp linux-firmware/i915/tgl_guc_70.bin /lib/firmware/i915
    sudo cp linux-firmware/i915/tgl_huc.bin /lib/firmware/i915

    # Update initramfs
    sudo update-initramfs -u -k all

    # Clean up
    cd $WORK_DIR
    del_existing_folder $WORK_DIR/firmware_install

    reboot_required=1
}

function sriov_install_kernel() {
    if [[ $USE_PPA_FILES -ne 1 ]]; then
        # Create temporary folder
        del_existing_folder $WORK_DIR/kernel_install
        mkdir $WORK_DIR/kernel_install
        cd $WORK_DIR/kernel_install

        # Clone source code from github
        git clone --branch lts-v6.6.32-linux-240605T051235Z --depth 1 https://github.com/intel/linux-intel-lts.git
        cd linux-intel-lts
        cp $WORK_DIR/sriov_patches/lts-v6.6.32-linux-240605T051235Z/x86_64_defconfig ./.config
        ./scripts/config --disable DEBUG_INFO

        # Build kernel
        echo "" | make ARCH=x86_64 olddefconfig
        make ARCH=x86_64 -j$(nproc) LOCALVERSION=-debian-sriov bindeb-pkg

        # Record down kernel version from file
        kernel_file_version=$(ls ../linux-headers*.deb | grep -Po 'linux-headers-\K[^_]*')

        # Install kernel
        sudo rm -rf ../*dbg*.deb
        sudo dpkg -i ../*.deb

        # Clean up
        cd $WORK_DIR
        del_existing_folder $WORK_DIR/kernel_install
    else
        # Install from ppa
        sudo -E curl -SsL -o /etc/apt/trusted.gpg.d/thundersoft-sriov.asc https://ThunderSoft-SRIOV.github.io/ppa/debian/doc/KEY.gpg
        sudo -E curl -SsL -o /etc/apt/sources.list.d/thundersoft-sriov.list https://ThunderSoft-SRIOV.github.io/ppa/debian/doc/thundersoft-sriov.list
        sudo apt update
        sudo apt install -y linux-image-6.6.32-debian-sriov linux-headers-6.6.32-debian-sriov linux-libc-dev
        kernel_file_version="6.6.32-debian-sriov"
    fi

    reboot_required=1
}

function sriov_update_grub() {
    # Retrieve installed debian-sriov kernel names
    readarray -t kernel_pkg_version < <(dpkg -l | grep "linux-headers*" | grep "debian-sriov" | grep ^ii | grep -Po 'linux-headers-\K[^ ]*')

    # Check the installed package for matching version
    match_found=0
    for entry in ${kernel_pkg_version[@]}; do
        if [ $entry == $kernel_file_version ]; then
            match_found=1
            break
        fi
    done

    if [ $match_found -ne 1 ]; then
        echo "Error: kernel version not found in installed package list" | tee -a $WORK_DIR/$LOG_FILE
        exit
    fi

    # Update default grub
    sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=\"Advanced options for Debian GNU\/Linux\>Debian GNU\/Linux, with Linux $kernel_file_version\"/g" /etc/default/grub
    sudo update-grub

    reboot_required=1
}

function show_help() {
    printf "$(basename "$0") [-h] [--use-ppa-files]\n"
    printf "Options:\n"
    printf "\t-h                    show this help message\n"
    printf "\t--use-ppa-files       setup with ppa files for faster setup\n"
}

function parse_arg() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|-\?|--help)
                show_help
                exit
                ;;

            --use-ppa-files)
                USE_PPA_FILES=1
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

function check_os() {
    # Check OS
    local version=`cat /proc/version`
    if [[ ! $version =~ "Debian" ]]; then
        echo "Error: Only Debian is supported" | tee -a $WORK_DIR/$LOG_FILE
        exit
    fi

    # Check Debian version
    req_version="12"
    cur_version=$(lsb_release -rs)
    if [[ $cur_version != $req_version ]]; then
        echo "Error: Debian $cur_version is not supported" | tee -a $WORK_DIR/$LOG_FILE
        echo "Error: Please use Debian $req_version" | tee -a $WORK_DIR/$LOG_FILE
        exit
    fi

    # Check for Intel BSP image
    if [[ $(apt-cache policy | grep http | awk '{print $2}' | grep intel | wc -l) > 0 ]]; then
        IS_BSP=1
        echo "Warning: Intel BSP image detected. Kernel installation skipped"
    fi
}

#----------------------------------       Main Processes      --------------------------------------

source $WORK_DIR/scripts/functions.sh

parse_arg "$@" || exit -1

log_clean
log_func check_os
log_func check_network

# Check if kernel needs to be installed
if [[ $IS_BSP -ne 1 ]]; then
    log_func sriov_add_source_list
    log_func sriov_install_packages
    log_func sriov_install_firmware
    log_func sriov_install_kernel
    log_func sriov_update_grub
fi

log_success
ask_reboot

echo "Done: \"$BASH_SOURCE $@\""
