#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -eE

#---------      Global variable     -------------------
reboot_required=0
kernel_maj_ver=0
WORK_DIR=$(pwd)
LOG_FILE="sriov_setup_ubuntu.log"
PACKAGES_DIR=$WORK_DIR/packages
BUILD_DIR=$WORK_DIR/sriov_build
INSTALL_DIR=$WORK_DIR/sriov_install


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

    # Check image against selected bsp argument
    intel_ppa=$(apt-cache policy | grep http | awk '{print $2}' | grep intel | wc -l)
    if [[ $intel_ppa > 0 ]] && [[ $IS_BSP -ne 1 ]]; then
        echo "Error: Intel BSP image detected. Use --bsp argument to run setup"
        exit
    elif [[ $intel_ppa == 0 ]] && [[ $IS_BSP -eq 1 ]]; then
        echo "Error: Intel BSP image not detected. Do not use --bsp argument to run setup"
        exit
    fi
}

function check_kernel_version() {
    local cur_ver=$(uname -r)
    local req_ver="6.6.32-ubuntu-sriov"
    kernel_maj_ver=${cur_ver:0:1}

    if [[ $IS_BSP -ne 1 ]]; then
        if [[ ! $cur_ver =~ $req_ver ]]; then
            echo "Error: Detected Linux version is $cur_ver" | tee -a $WORK_DIR/$LOG_FILE
            echo "Error: Please install and boot with an $req_ver kernel" | tee -a $WORK_DIR/$LOG_FILE
            exit
        fi
    fi
}

function check_network(){

    if [[ $USE_INSTALL_FILES -ne 1 ]]; then
        websites=("https://github.com/"
                  "https://wayland.freedesktop.org/"
                  "https://gstreamer.freedesktop.org/"
                  "https://gitlab.freedesktop.org/mesa/"
                  "https://gitlab.freedesktop.org/spice/"
                  "https://gitlab.com/virt-viewer/")
    else
        websites=("https://github.com/"
                  "https://wayland.freedesktop.org/"
                  "https://gstreamer.freedesktop.org/")
    fi

    set +e
    for site in ${websites[@]}; do
        echo "Checking $site"
        wget --timeout=10 --tries=1 $site -nv --spider
        if [ $? -ne 0 ]; then
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
    set -e
}

function del_existing_folder() {
    if [ -d "$1" ]; then
        echo "Deleting existing folder $1"
        rm -fr $1
    fi
}


function sriov_check_files(){
    # Check for SRIOV patches
    if [ ! -d "$WORK_DIR/sriov_patches" ]; then
        echo "Error: $WORK_DIR/sriov_patches folder is missing" | tee -a $WORK_DIR/$LOG_FILE
        exit
    fi

    # Check for dependent scripts
    if [ ! -f $WORK_DIR/sriov_prepare_projects.sh ]; then
        echo "Error: $WORK_DIR/sriov_prepare_projects.sh file is missing" | tee -a $WORK_DIR/$LOG_FILE
        exit
    fi

    if [ ! -f $WORK_DIR/sriov_install_projects.sh ]; then
        echo "Error: $WORK_DIR/sriov_install_projects.sh file is missing" | tee -a $WORK_DIR/$LOG_FILE
        exit
    fi

    # Check for install files
    if [[ $USE_INSTALL_FILES -eq 1 ]]; then
        folders=("$PACKAGES_DIR"
                 "$INSTALL_DIR"
                 "$INSTALL_DIR/neo")

        for folder in ${folders[@]}; do
            do_exists=$(ls $folder 2> /dev/null | wc -l)
            if [ "$do_exists" == "0" ]; then
                echo "Error: $folder folder is missing" | tee -a $WORK_DIR/$LOG_FILE
                exit
            fi
        done
    fi
}

function sriov_disable_auto_upgrade(){
    # Stop existing upgrade service
    sudo systemctl stop unattended-upgrades.service
    sudo systemctl disable unattended-upgrades.service
    sudo systemctl mask unattended-upgrades.service

    auto_upgrade_config=("APT::Periodic::Update-Package-Lists"
                         "APT::Periodic::Unattended-Upgrade"
                         "APT::Periodic::Download-Upgradeable-Packages"
                         "APT::Periodic::AutocleanInterval")

    # Disable auto upgrade
    for config in ${auto_upgrade_config[@]}; do
        if [[ ! `cat /etc/apt/apt.conf.d/20auto-upgrades` =~ "$config" ]]; then
            echo -e "$config \"0\";" | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades
        else
            sed -i "s/$config \"1\";/$config \"0\";/g" /etc/apt/apt.conf.d/20auto-upgrades
        fi
    done

    reboot_required=1
}

function sriov_add-universe-multiverse(){
    # Add repository and update
    sudo add-apt-repository -y universe
    sudo add-apt-repository -y multiverse
    sudo apt-get update
}

function sriov_prepare_install(){
    # Install prerequites for projects installation
    source $WORK_DIR/sriov_prepare_projects.sh
}

function sriov_main_install(){
    # Start projects installation
    source $WORK_DIR/sriov_install_projects.sh
}

function sriov_customise_ubu(){
    # Switch to Xorg
    sed -i "s/\#WaylandEnable=false/WaylandEnable=false/g" /etc/gdm3/custom.conf

    if [[ $GUEST_SETUP == 1 ]]; then
        # Configure X11 wrapper and mesa loader for Ubuntu guest
        if ! grep -Fq 'needs_root_rights=no' /etc/X11/Xwrapper.config; then
            echo 'needs_root_rights=no' | sudo tee -a /etc/X11/Xwrapper.config
        fi
        if ! grep -Fq 'source /etc/profile.d/mesa_driver.sh' /etc/bash.bashrc; then
            echo 'source /etc/profile.d/mesa_driver.sh' | sudo tee -a /etc/bash.bashrc
        fi
        if ! grep -Fq 'export MESA_LOADER_DRIVER_OVERRIDE=pl111' /etc/environment; then
            echo 'export MESA_LOADER_DRIVER_OVERRIDE=pl111' | sudo tee -a /etc/environment
        fi

        # Enable SW cursor for Ubuntu guest
        echo -e "Section \"Device\"" | sudo tee -a /usr/share/X11/xorg.conf.d/20-modesetting.conf
        echo -e "Identifier \"VirtIO-GPU\"" | sudo tee -a /usr/share/X11/xorg.conf.d/20-modesetting.conf
        echo -e "Driver \"modesetting\"" | sudo tee -a /usr/share/X11/xorg.conf.d/20-modesetting.conf
        echo -e "#BusID \"PCI:0:4:0\" #virtio-gpu" | sudo tee -a /usr/share/X11/xorg.conf.d/20-modesetting.conf
        echo -e "Option \"SWcursor\" \"true\"" | sudo tee -a /usr/share/X11/xorg.conf.d/20-modesetting.conf
        echo -e "EndSection" | sudo tee -a /usr/share/X11/xorg.conf.d/20-modesetting.conf
    fi

#    # Load br_netfilter
#    echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf

#    # Allow no password
#    username=$(logname)
#    echo "$username ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/$username-sudo
#    chmod 440 /etc/sudoers.d/$username-sudo

    reboot_required=1
}

function sriov_setup_pwr_ctrl(){
    source $WORK_DIR/sriov_setup_pwr_ctrl.sh

    if [[ $GUEST_SETUP == 1 ]]; then
        # install qemu-update-agent for guest only
        sriov_install_agent
    else
        # setup hugepg workaround for host only
        sriov_setup_hugepg
        sriov_setup_resume_guest
        sriov_install_qmp
    fi

    # setup swap file for both host and guest
    sriov_setup_swapfile
}

function sriov_setup_swtpm() {
    # Install libtpms and swtpm
    sudo apt-get -y install libtpms-dev swtpm

    # Update apparmor profile usr.bin.swtpm
    sed -i "s/#include <tunables\/global>/include <tunables\/global>/g" /etc/apparmor.d/usr.bin.swtpm
    sed -i "s/#include <abstractions\/base>/include <abstractions\/base>/g" /etc/apparmor.d/usr.bin.swtpm
    sed -i "s/#include <abstractions\/openssl>/include <abstractions\/openssl>\n  include <abstractions\/libvirt-qemu>/g" /etc/apparmor.d/usr.bin.swtpm
    sed -i "s/#include <local\/usr.bin.swtpm>/include <local\/usr.bin.swtpm>/g" /etc/apparmor.d/usr.bin.swtpm

    # Update local apparmor profile usr.bin.swtpm
    local_swtpm_profile=("owner /home/**/vtpm0/.lock wk,"
                         "owner /home/**/vtpm0/swtpm-sock w,"
                         "owner /home/**/vtpm0/TMP2-00.permall rw,"
                         "owner /home/**/vtpm0/tpm2-00.permall rw,")

    for rule in "${local_swtpm_profile[@]}"; do
        if [[ ! `cat /etc/apparmor.d/local/usr.bin.swtpm` =~ "$rule" ]]; then
            echo -e "$rule" | sudo tee -a /etc/apparmor.d/local/usr.bin.swtpm
        fi
    done
    # Load profile
    sudo apparmor_parser -r /etc/apparmor.d/usr.bin.swtpm
}

function sriov_update_cmdline(){

    local updated=0

    if [ $kernel_maj_ver -eq 5 ]; then
        cmds=("i915.force_probe=*"
              "intel_iommu=on"
              "udmabuf.list_limit=8192"
              "i915.enable_guc=(0x)?0*7")
    elif [ $kernel_maj_ver -eq 6 ]; then
        cmds=("i915.force_probe=*"
              "intel_iommu=on"
              "udmabuf.list_limit=8192"
              "i915.enable_guc=(0x)?(0)*3")
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
        update-grub
        reboot_required=1
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

function show_help() {
    printf "$(basename "$0") [-h] [--bsp] [--use-install-files]\n"
    printf "Options:\n"
    printf "\t-h                    show this help message\n"
    printf "\t--bsp                 setup host for Ubuntu BSP\n"
    printf "\t--use-install-files   setup with install files for faster setup\n"
}

function parse_arg() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|-\?|--help)
                show_help
                exit
                ;;

            --bsp)
                IS_BSP=1
                ;;

            --use-install-files)
                USE_INSTALL_FILES=1
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


#-------------    main processes    -------------

parse_arg "$@" || exit -1

log_clean
log_func check_os
log_func check_kernel_version
log_func check_network
if [[ $IS_BSP -ne 1 ]]; then

    log_func sriov_check_files
fi
#log_func sriov_disable_auto_upgrade
if [[ $IS_BSP -ne 1 ]]; then
    log_func sriov_add-universe-multiverse
    log_func sriov_prepare_install
    log_func sriov_main_install
fi
log_func sriov_customise_ubu
log_func sriov_setup_pwr_ctrl
log_func sriov_setup_swtpm
log_func sriov_update_cmdline
log_success
ask_reboot

echo "Done: \"$(realpath $0) $@\""
