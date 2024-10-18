#!/bin/bash

# Copyright (c) 2022 Intel Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -eE

#---------      Global variable     -------------------
reboot_required=0
kernel_file_version=0
WORK_DIR=$(pwd)
LOG_FILE="sriov_setup_kernel.log"

#---------      Functions    -------------------

function log_func() {
    if [ "$(type -t $1)" = "function" ]; then
        start=`date +%s`
        echo -e "$(date)   start:   \t$@" >> $WORK_DIR/$LOG_FILE
        $@
        end=`date +%s`
        echo -e "$(date)   end ($((end-start))s):\t$@" >> $WORK_DIR/$LOG_FILE
    else
        echo "Error: $1 is not a function"
        exit
    fi
}

function log_clean(){
    # Clean up log file
    if [ -f "$WORK_DIR/$LOG_FILE" ]; then
        rm $WORK_DIR/$LOG_FILE
    fi
}

function check_os() {
    # Check OS
    local version=`cat /proc/version`
    if [[ ! $version =~ "Ubuntu" ]]; then
        echo "Error: Only Ubuntu is supported" | tee -a $WORK_DIR/$LOG_FILE
        exit
    fi

    # Check Ubuntu version
    req_version="22.04"
    cur_version=$(lsb_release -rs)
    if [[ $cur_version != $req_version ]]; then
        echo "Error: Ubuntu $cur_version is not supported" | tee -a $WORK_DIR/$LOG_FILE
        echo "Error: Please use Ubuntu $req_version" | tee -a $WORK_DIR/$LOG_FILE
        exit
    fi

    # Check for Intel BSP image
    if [[ $(apt-cache policy | grep http | awk '{print $2}' | grep intel | wc -l) > 0 ]]; then
        IS_BSP=1
        echo "Warning: Intel BSP image detected. Kernel installation skipped"
    fi
}

function check_network(){
    websites=("https://git.kernel.org/"
              "https://github.com/")

    for site in ${websites[@]}; do
        echo "Checking $site"
        wget --timeout=10 --tries=1 $site -nv --spider
        if [ $? -ne 0 ]; then
            echo "Error: Network issue, unable to access $site" | tee -a $WORK_DIR/$LOG_FILE
            echo "Error: Please check the internet access connection" | tee -a $WORK_DIR/$LOG_FILE
            exit
        fi
    done
}

function del_existing_folder() {
    if [ -d "$1" ]; then
        echo "Deleting existing folder $1"
        rm -fr $1
    fi
}

function sriov_check_files(){
    # Check for dependent script
    if [ ! -f $WORK_DIR/sriov_download_firmware.sh ]; then
        echo "Error: $WORK_DIR/sriov_download_firmware.sh file is missing" | tee -a $WORK_DIR/$LOG_FILE
        exit
    fi

    # Check for kernel
    if [ ! -f $WORK_DIR/lts202[12]-iotg-kernel-rel.tar.gz ]; then
        # Check for kernel deb files
        deb_files=("linux-headers-*-lts202[12]-iotg_*.deb"
                   "linux-image-*-lts202[12]-iotg_*.deb"
                   "linux-libc-*-lts202[12]-iotg-*.deb")
        file_missing=0
        for file in ${deb_files[@]}; do
            if [ ! -f $WORK_DIR/$file ]; then
                echo "Error: $WORK_DIR/$file file is missing" | tee -a $WORK_DIR/$LOG_FILE
                file_missing=1
            fi
        done

        if [ $file_missing -eq 1 ]; then
            echo "Error: $WORK_DIR/lts202[12]-iotg-kernel-rel.tar.gz file is missing" | tee -a $WORK_DIR/$LOG_FILE
            exit
        fi
    fi
}

function sriov_install_firmware(){
    # Create temporary folder
    del_existing_folder $WORK_DIR/firmware_install
    mkdir $WORK_DIR/firmware_install
    cd $WORK_DIR/firmware_install

    # Download firmware for SRIOV
    source $WORK_DIR/sriov_download_firmware.sh

    # Clean up
    cd $WORK_DIR
    del_existing_folder $WORK_DIR/firmware_install

    reboot_required=1
}

function sriov_ax210_workaround(){
    # Workaround for firmware loading issue for AX210
    local update_initramfs=0
    if [ -f /lib/firmware/iwlwifi-ty-a0-gf-a0-66.ucode ]; then
        sudo mv /lib/firmware/iwlwifi-ty-a0-gf-a0-66.ucode /lib/firmware/iwlwifi-ty-a0-gf-a0-66.ucode.bak
        update_initramfs=1
    fi
    if [ -f /lib/firmware/iwlwifi-ty-a0-gf-a0.pnvm ] &&
       [[ "$kernel_file_version" == "5.10."* ]]; then
        sudo mv /lib/firmware/iwlwifi-ty-a0-gf-a0.pnvm /lib/firmware/iwlwifi-ty-a0-gf-a0.pnvm.bak
        update_initramfs=1
    fi

    if [ $update_initramfs -eq 1 ]; then
        sudo update-initramfs -u -k all
    fi
}

function sriov_install_kernel(){
       if [[ $USE_INSTALL_FILES -ne 1 ]]; then
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
        make ARCH=x86_64 -j$(nproc) LOCALVERSION=-ubuntu-sriov bindeb-pkg

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
        sudo curl -SsL -o /etc/apt/trusted.gpg.d/thundersoft-sriov.asc https://ThunderSoft-SRIOV.github.io/ppa/debian/KEY.gpg
        sudo curl -SsL -o /etc/apt/sources.list.d/thundersoft-sriov.list https://ThunderSoft-SRIOV.github.io/ppa/debian/thundersoft-sriov.list
        sudo apt update
        sudo apt install -y linux-image-6.6.32-debian-sriov linux-headers-6.6.32-debian-sriov linux-libc-dev
        kernel_file_version="6.6.32-debian-sriov"
    fi

    reboot_required=1
}

function sriov_update_grub(){
    # Retrieve installed lts202[12]-iotg kernel names
    readarray -t kernel_pkg_version < <(dpkg -l | grep "linux-headers*" | grep "lts202[12]-iotg" | grep ^ii | grep -Po 'linux-headers-\K[^ ]*')

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
    sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT='Advanced options for Ubuntu>Ubuntu, with Linux $kernel_file_version'/g" /etc/default/grub
    sudo update-grub

    reboot_required=1
}

log_success(){
    echo "Success" | tee -a $WORK_DIR/$LOG_FILE
}

function ask_reboot(){
    if [ $reboot_required -eq 1 ];then
        echo "Please reboot system to take effect"
    fi
}

#-------------    main processes    -------------

log_clean
log_func check_os
log_func check_network

# Check if kernel needs to be installed
if [[ $IS_BSP -ne 1 ]]; then
    #log_func sriov_check_files
    log_func sriov_install_firmware
    log_func sriov_install_kernel
    log_func sriov_ax210_workaround
    log_func sriov_update_grub
fi

log_success
ask_reboot

echo "Done: \"$BASH_SOURCE $@\""
