#!/bin/bash

set -eE

#----------------------------------      Global variable      --------------------------------------

WORK_DIR=$(pwd)
SCRIPT_NAME=$(basename "$0")
LOG_FILE=${SCRIPT_NAME%.*}.log

reboot_required=0
kernel_file_version=6.6-intel

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

function ask_reboot(){
    if [ $reboot_required -eq 1 ];then
        echo "Please reboot system to take effect"
    fi
}

function check_kernel_version() {
    local cur_ver=$(uname -r)
    local req_ver="6.6-intel"
    kernel_maj_ver=${cur_ver:0:1}

    if [[ $IS_BSP -ne 1 ]]; then
        if [[ ! $cur_ver =~ $req_ver ]]; then
            echo "Error: Detected Linux version is $cur_ver" | tee -a $WORK_DIR/$LOG_FILE
            echo "Error: Please install and boot with an $req_ver kernel" | tee -a $WORK_DIR/$LOG_FILE
            exit
        fi
    fi
}

function sriov_update_cmdline(){

    local updated=0

    if [[ $kernel_maj_ver -eq 5 ]]; then
        cmds=("i915.force_probe=*"
              "intel_iommu=on"
              "udmabuf.list_limit=8192"
              "i915.enable_guc=(0x)?0*7")
    elif [[ $kernel_maj_ver -eq 6 ]]; then
        cmds=("i915.force_probe=*"
              "intel_iommu=on"
              "udmabuf.list_limit=8192"
              "i915.enable_guc=(0x)?(0)*3"
              "i915.max_vfs=(0x)?(0)*7")
    fi

    cmdline=$(sed -n -e "/.*\(GRUB_CMDLINE_LINUX=\).*/p" /etc/default/grub)
    cmdline=$(awk -F '"' '{print $2}' <<< $cmdline)

    for cmd in ${cmds[@]}; do
        if [[ ! $cmdline =~ $cmd ]]; then
            # Special handling for i915.enable_guc and i915.max_vfs
            if [[ $cmd == "i915.enable_guc=(0x)?0*7" ]]; then
                cmdline=$(sed -r -e "s/\<i915.enable_guc=(0x)?([A-Fa-f0-9])*\>//g" <<< $cmdline)
                cmd="i915.enable_guc=0x7"
            elif [[ $cmd == "i915.enable_guc=(0x)?(0)*3" ]]; then
                cmdline=$(sed -r -e "s/\<i915.enable_guc=(0x)?([A-Fa-f0-9])*\>//g" <<< $cmdline)
                cmd="i915.enable_guc=0x3"
            elif [[ $cmd == "i915.max_vfs=(0x)?(0)*7" ]]; then
                cmdline=$(sed -r -e "s/\<i915.max_vfs=(0x)?([0-9])*\>//g" <<< $cmdline)
                cmd="i915.max_vfs=7"
            fi

            cmdline=$(echo $cmdline $cmd)
            updated=1
        fi
    done

    if [[ updated -eq 1 ]]; then
        sed -i -r -e "s/(GRUB_CMDLINE_LINUX=).*/GRUB_CMDLINE_LINUX=\" $cmdline \"/" /etc/default/grub
        sudo update-grub
        reboot_required=1
    fi
}

function show_help() {
    printf "$(basename "$0") [-h]\n"
    printf "Options:\n"
    printf "\t-h                    show this help message\n"
}

function parse_arg() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|-\?|--help)
                show_help
                exit
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

log_clean

log_func check_kernel_version
log_func sriov_update_cmdline

log_success
ask_reboot

echo "Done: \"$BASH_SOURCE $@\""
