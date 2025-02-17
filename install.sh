#!/bin/bash

set -x

#----------------------------------      Global variable      --------------------------------------

WORK_DIR=$(pwd)
LOG_FILE="install.log"
reboot_required=0
kernel_maj_ver=6

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

function check_network() {
    websites=("https://github.com/")

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

function sriov_add_source_list() {
    # Add repository and update
    sudo echo 'deb http://ftp.de.debian.org/debian sid main' | sudo tee -a /etc/apt/sources.list.d/debian_sriov.list
    sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D' /etc/apt/sources.list.d/debian_sriov.list
    sudo curl -SsL -o /etc/apt/sources.list.d/thundersoft-sriov.list https://ThunderSoft-SRIOV.github.io/ppa/debian/doc/thundersoft-sriov.list
    sudo curl -SsL -o /etc/apt/trusted.gpg.d/thundersoft-sriov.asc https://ThunderSoft-SRIOV.github.io/ppa/debian/doc/KEY.gpg
    sudo apt update
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

#----------------------------------       Main Processes      --------------------------------------

log_func check_network
log_func sriov_add_source_list

log_func sriov_update_cmdline

# install kernel
sudo apt install -y linux-image-6.6-intel linux-headers-6.6-intel linux-libc-dev

# install firmware
sudo apt install -y ovmf

# install gstreamer
sudo apt install -y --allow-downgrades gir1.2-gst-plugins-bad-1.0=1.24.7-1ppa1~noble3 gir1.2-gst-plugins-base-1.0=1.24.7-1ppa1~noble1 \
                    gir1.2-gstreamer-1.0=1.24.7-1ppa1~noble1 gir1.2-gst-rtsp-server-1.0=1.24.7-1ppa1~noble1 \
                    gstreamer1.0-alsa=1.24.7-1ppa1~noble1 gstreamer1.0-gl=1.24.7-1ppa1~noble1 \
                    gstreamer1.0-gtk3=1.24.7-1ppa1~noble1 gstreamer1.0-opencv=1.24.7-1ppa1~noble3 \
                    gstreamer1.0-plugins-bad=1.24.7-1ppa1~noble3 gstreamer1.0-plugins-bad-apps=1.24.7-1ppa1~noble3 \
                    gstreamer1.0-plugins-base=1.24.7-1ppa1~noble1 gstreamer1.0-plugins-base-apps=1.24.7-1ppa1~noble1 \
                    gstreamer1.0-plugins-good=1.24.7-1ppa1~noble1 gstreamer1.0-plugins-ugly=1.24.7-1ppa1~noble1 \
                    gstreamer1.0-pulseaudio=1.24.7-1ppa1~noble1 gstreamer1.0-qt5=1.24.7-1ppa1~noble1 gstreamer1.0-rtsp=1.24.7-1ppa1~noble1 \
                    gstreamer1.0-tools=1.24.7-1ppa1~noble1 gstreamer1.0-x=1.24.7-1ppa1~noble1 \
                    libgstreamer-gl1.0-0=1.24.7-1ppa1~noble1 libgstreamer-opencv1.0-0=1.24.7-1ppa1~noble3 libgstreamer-plugins-bad1.0-0=1.24.7-1ppa1~noble3 \
                    libgstreamer-plugins-bad1.0-dev=1.24.7-1ppa1~noble3 libgstreamer-plugins-base1.0-0=1.24.7-1ppa1~noble1 \
                    libgstreamer-plugins-base1.0-dev=1.24.7-1ppa1~noble1 libgstreamer1.0-dev=1.24.7-1ppa1~noble1 libgstreamer1.0-0=1.24.7-1ppa1~noble1 \
                    libgstrtspserver-1.0-dev=1.24.7-1ppa1~noble1 libgstrtspserver-1.0-0=1.24.7-1ppa1~noble1

