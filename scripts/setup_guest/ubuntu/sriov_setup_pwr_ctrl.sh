#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -eE

#---------      Global variable     -------------------

# This global should be uncommented when the script is
# copied to the Ubuntu guest during guest setup.
GUEST_SCRIPT=1

#---------      Functions    -------------------


function sriov_install_agent {
    sudo apt-get install -y qemu-guest-agent
}


function sriov_setup_hugepg {
    # Workaround for S4 hugepages/RAM allocation issue.
    # As for now, to Hibernate, RAM need to be free up 50%.
    # Reference: https://www.kernel.org/doc/Documentation/power/pci.rst (2.4.3. System Hibernation)

    echo '#!/bin/sh
    PATH=:/sbin:/usr/sbin:/bin:/usr/bin

    case "$1" in
         pre)
             #code execution BEFORE sleeping/hibernating/suspending
             echo XDCI > /proc/acpi/wakeup
             echo XHCI > /proc/acpi/wakeup
             echo GLAN > /proc/acpi/wakeup
             nr_hugepg=$(cat /proc/sys/vm/nr_hugepages)
             echo "nr_hugepg=$nr_hugepg"
             echo "$nr_hugepg" > /lib/systemd/system-sleep/hugepage_restore.txt
             echo "0" > /proc/sys/vm/nr_hugepages
         ;;
         post)
             #code execution AFTER resuming
             echo XDCI > /proc/acpi/wakeup
             echo XHCI > /proc/acpi/wakeup
             echo GLAN > /proc/acpi/wakeup
             restore=$(cat /lib/systemd/system-sleep/hugepage_restore.txt)
             echo $restore > /proc/sys/vm/nr_hugepages
             rm /lib/systemd/system-sleep/hugepage_restore.txt ' >> hugepage_s4.sh
    echo '    ;;
    esac

    exit 0' >> hugepage_s4.sh

    mv hugepage_s4.sh /lib/systemd/system-sleep/
    chmod +x /lib/systemd/system-sleep/hugepage_s4.sh
}

function sriov_setup_swapfile {
    # Setup swapfile to allow for hibernate for both host and guest
    # The swap size needs to be larger than the total size of RAM

    # check RAM size
    ram_total=$(free --giga | awk '{ if ($1 == "Mem:") { print $2 }}')

    # determine swap size needed
    # based on table from https://help.ubuntu.com/community/SwapFaq
    # key=ram size, value=swap size
    declare -A swap_tbl
    swap_tbl=( ["1"]="2"
               ["2"]="3"
               ["3"]="5"
               ["4"]="6"
               ["5"]="7"
               ["6"]="8"
               ["8"]="11"
               ["12"]="15"
               ["16"]="20"
               ["24"]="29"
               ["32"]="38"
               ["64"]="72"
               ["128"]="139"
               ["256"]="272"
               ["512"]="535"
               ["1024"]="1056"
               ["2048"]="2094"
               ["4096"]="4160"
               ["8192"]="8283"
             )

    for ram_sz in $(for k in ${!swap_tbl[@]}; do echo $k; done | sort -n); do
        if [ "$ram_total" -le "$ram_sz" ]; then
            swapfile_req=${swap_tbl[$ram_sz]}
            break
        fi
    done

    # check if current swapfile fulfills required size
    if [ -f "/swapfile" ]; then
        swapfile_cur=$(swapon --show | awk '{ if ($1 ~ "/swapfile") { print int($3) }}')
    else
        swapfile_cur=0
    fi
    if [ $swapfile_cur -lt $swapfile_req ]; then
        # setup swapfile with required size

        # check free disk space
        if [ $(df -h / | awk '{ if ($1 ~ "/dev") { print int($4) }}') -gt $swapfile_req ]; then
            echo "Setting up swapfile with size ${swapfile_req}G"

            if [ -f "/swapfile" ]; then
                # disable swapfile
                sudo swapoff /swapfile
                sudo rm /swapfile
            fi

            # allocate swapfile
            sudo fallocate -l ${swapfile_req}G /swapfile
            sudo chmod 600 /swapfile

            # create swapfile
            sudo mkswap /swapfile

            # start to use swapfile
            sudo swapon /swapfile
        else
            echo "Error: not enough free disk space for swapfile"
            exit
        fi
    fi

    # add swapfile to /etc/fstab if needed
    if ! grep -q swapfile "/etc/fstab"; then
        echo '/swapfile       none            swap    sw              0       0' | sudo tee -a /etc/fstab
    fi

    # check swapfile UUID
    swap_uuid=$(sudo findmnt -no UUID -T /swapfile)

    # check swap file offset
    swap_file_offset=$(sudo filefrag -v /swapfile | awk '{ if($1=="0:"){print substr($4, 1, length($4)-2)} }')

    # cleanup and update grub
    if [[ `cat /etc/default/grub` =~ "resume=UUID=" ]] || [[ `cat /etc/default/grub` =~ "resume_offset=" ]]; then
        sed -i "s/resume=UUID=[A-Za-z0-9\-]*\s\{0,1\}//" /etc/default/grub
        sed -i "s/resume_offset=[0-9]*\s\{0,1\}//" /etc/default/grub
    fi
    sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"resume=UUID=$swap_uuid resume_offset=$swap_file_offset /g" /etc/default/grub
    sudo update-grub

    # set resume overide
    echo "resume=UUID=$swap_uuid" > /etc/initramfs-tools/conf.d/resume
    sudo update-initramfs -u -k all
}


# Create resume_guest.sh under /lib/systemd/system-sleep to send
# qmp wakeup command to each guest after host wakeup.
function sriov_setup_resume_guest() {
    echo '#!/bin/sh
    PATH=:/sbin:/usr/sbin:/bin:/usr/bin

    send_wakeup() {
        qmp_sock_files=$(ls /tmp/qmp-pwr-socket-*)
        if [ $? != 0 ]; then
            echo "No VMs launched. QMP socket file not found"
            return
        fi

        for qmp_socket in $qmp_sock_files;
        do
            echo "$qmp_socket"' >> resume_guest.sh
    echo -n "            $PWD/pwr_ctrl_check_qemu.py" >> resume_guest.sh
    echo ' $qmp_socket "resume"
        done

        echo "Guest VMs are resumed"
    }

    # echo "parm1 = $1, parm2 = $2"
    if [ $1 = "post" ] && [ $2 = "suspend" ]; then
        send_wakeup
    fi

    exit 0' >> resume_guest.sh

    mv resume_guest.sh /lib/systemd/system-sleep/
    chmod +x /lib/systemd/system-sleep/resume_guest.sh
}

# install qemu.qmp lib for host
function sriov_install_qmp() {
    sudo pip3 install qemu.qmp==0.0.3
}

#-------------    main processes    -------------

# run only for guest and not during setup
# this should happen during startup
if [[ $GUEST_SCRIPT == 1 ]] && [[ $GUEST_SETUP != 1 ]]; then
    sriov_setup_swapfile
fi
