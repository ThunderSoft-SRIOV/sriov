#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -Ee

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

function check_network() {
    websites=("https://git.kernel.org/"
              "https://github.com/")

    for site in ${websites[@]}; do
        echo "Checking $site"       
        if ! wget --timeout=10 --tries=1 $site -nv --spider
        then
            echo "Error: Network issue, unable to access $site" | tee -a $WORK_DIR/$LOG_FILE
            echo "Error: Please check the internet access connection" | tee -a $WORK_DIR/$LOG_FILE
            echo "Solution to Network Problems One: Add a Proxy"
            echo "Proxy address depends on user environment. Usually by “export http_proxy=http://proxy_ip_url:proxy_port”"
            echo "Proxy address depends on user environment. Usually by “export https_proxy=https://proxy_ip_url:proxy_port”"
            echo "For example:"
            echo "export http_proxy=http://proxy-domain.com:912"
            echo "export https_proxy=http://proxy-domain.com:912"
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

function ask_reboot(){
    if [ $reboot_required -eq 1 ];then
        echo "Please reboot system to take effect"
    fi
}
