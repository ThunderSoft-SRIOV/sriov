#!/bin/bash

set -e

#----------------------------------      Global variable      --------------------------------------
WORK_DIR=$(pwd)
LOG_FILE="sriov_setup_debian.log"
reboot_required=0

#----------------------------------         Functions         --------------------------------------

function sriov_disable_auto_upgrade() {
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

function sriov_add_source_list() {
    # Add repository and update
    sudo echo 'deb http://deb.debian.org/debian bookworm-backports main non-free-firmware' | sudo tee -a /etc/apt/sources.list.d/debian_sriov.list
    sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D' /etc/apt/sources.list.d/debian_sriov.list
    sudo apt update
    sudo apt -t bookworm-backports upgrade 
}

function sriov_prepare_install(){
    # Install prerequites for projects installation
    source $WORK_DIR/scripts/setup_host/sriov_prepare_projects.sh
}

function sriov_main_install(){
    # Start projects installation
    source $WORK_DIR/scripts/setup_host/sriov_install_projects.sh
}

function sriov_customise_debian() {
    # Switch to Xorg
    sed -i "s/\#WaylandEnable=false/WaylandEnable=false/g" /etc/gdm3/daemon.conf

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

function sriov_setup_pwr_ctrl() {
    source $WORK_DIR/scripts/setup_host/sriov_setup_pwr_ctrl.sh

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
        update-grub
        reboot_required=1
    fi
}

function show_help() {
    printf "$(basename "$0") [-h] [--use-install-files]\n"
    printf "Options:\n"
    printf "\t-h                    show this help message\n"
    printf "\t--use-install-files   setup with install files for faster setup\n"
}

function parse_arg() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|-\?|--help)
                show_help
                exit
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

#----------------------------------       Main Processes      --------------------------------------

source $WORK_DIR/scripts/functions.sh

parse_arg "$@" || exit -1

log_clean
log_func check_os
log_func check_kernel_version

if [[ $IS_BSP -ne 1 ]]; then
    log_func check_network
fi

# log_func sriov_disable_auto_upgrade

if [[ $IS_BSP -ne 1 ]]; then
    log_func sriov_add_source_list
    log_func sriov_prepare_install
    log_func sriov_main_install
fi

log_func sriov_customise_debian
# log_func sriov_setup_pwr_ctrl
# log_func sriov_setup_swtpm
log_func sriov_update_cmdline
log_success
ask_reboot

echo "Done: \"$(realpath $0) $@\""
