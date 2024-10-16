#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -e

#----------------------------------      Global variable      --------------------------------------
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

#----------------------------------         Functions         --------------------------------------

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

function log_clean() {
    # Clean up log file
    if [ -f "$WORK_DIR/$LOG_FILE" ]; then
        rm $WORK_DIR/$LOG_FILE
    fi
}

function log_success() {
    echo "Success" | tee -a $WORK_DIR/$LOG_FILE
}

function check_build_error(){
    if [ $? -ne 0 ]; then
        echo -e "${RED}$1: Build Error ${NC}"
        exit -1
     else
         echo -e "${GREEN}$1: Build Success${NC}"
    fi
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

function check_kernel_version() {
    local cur_ver=$(uname -r)
    local req_ver="6.6.32-debian-sriov"
    kernel_maj_ver=${cur_ver:0:1}

    if [[ $IS_BSP -ne 1 ]]; then
        if [[ ! $cur_ver =~ $req_ver ]]; then
            echo "Error: Detected Linux version is $cur_ver" | tee -a $WORK_DIR/$LOG_FILE
            echo "Error: Please install and boot with an $req_ver kernel" | tee -a $WORK_DIR/$LOG_FILE
            exit
        fi
    fi
}

function check_network() {
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

function log_success(){
    echo "Success" | tee -a $WORK_DIR/$LOG_FILE
}

function ask_reboot(){
    if [ $reboot_required -eq 1 ];then
        echo "Please reboot system to take effect"
    fi
}
