#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -x


sudo chmod -t /tmp
#------------------------------------------------------      Global variable    ----------------------------------------------------------
kernel_maj_ver=0
WORK_DIR=$PWD
SETUP_LOCK=/tmp/sriov.setup.lock
VF_USED=0
HUGEPG_ALLOC=0

EMULATOR_PATH=$(which qemu-system-x86_64)
MAX_NUM_GUEST=7
MAX_USB_REDIR_CHANNEL=16
GUEST_NAME="-name ubuntu-vm"
GUEST_MEM="-m 2G"
GUEST_CPU_NUM="-smp cores=2,threads=2,sockets=1"
GUEST_DISK="-drive file=$WORK_DIR/ubuntu.qcow2,if=virtio,id=ubuntu_disk,format=qcow2,cache=none"
GUEST_FIRMWARE="\
 -drive file=$WORK_DIR/OVMF_CODE.fd,format=raw,if=pflash,unit=0,readonly=on \
 -drive file=$WORK_DIR/OVMF_VARS_ubuntu.fd,format=raw,if=pflash,unit=1"
GUEST_DISP_TYPE="-display gtk,gl=on,show-fps=on"
GUEST_DISPLAY_MAX=2
GUEST_DISPLAY_MIN=1
GUEST_MAX_OUTPUTS=2
GUEST_FULL_SCREEN=0
GUEST_KIRQ_CHIP=
GUEST_VGA_DEV="-device virtio-gpu-pci"
GUEST_MAC_ADDR="DE:AD:BE:EF:B1:12"
GUEST_NET="\
 -device e1000,netdev=net0,mac=$GUEST_MAC_ADDR \
 -netdev user,id=net0,hostfwd=tcp::2222-:22"
GUEST_EXTRA_QCMD=
GUEST_USB_PT_DEV=
GUEST_UDC_PT_DEV=
GUEST_AUDIO_PT_DEV=
GUEST_ETH_PT_DEV=
GUEST_WIFI_PT_DEV=
GUEST_PCI_PT_ARRAY=()
GUEST_USB_XHCI_OPT="-device qemu-xhci,id=xhci"
GUEST_QGA_OPT=
GUEST_QMP_OPT=
GUEST_PWR_CTRL=0
GUEST_SPICE_OPT=
GUEST_SPICE_DISPLAY="egl-headless"
GUEST_SPICE_PORT="3002"
GUEST_SPICE_TICKETING="on"
GUEST_SPICE_AUDIO_NAME="spice_snd"
GUEST_AUDIO_DEV=
GUEST_AUDIO_ARCH="intel-hda"
GUEST_AUDIO_NAME="hda-audio"
GUEST_AUDIO_SERVER="unix:/run/user/1000/pulse/native"
GUEST_AUDIO_SINK="alsa_output.pci-0000_00_1f.3.analog-stereo"
GUEST_AUDIO_TIMER="5000"
GUEST_STATIC_OPTION="\
 -enable-kvm \
 -k en-us \
 -cpu host"

#------------------------------------------------------         Functions       ----------------------------------------------------------
function check_kernel_version() {
    local cur_ver=$(uname -r | sed "s/\([0-9.]*\).*/\1/")
    local req_ver="5.10.0"
    kernel_maj_ver=${cur_ver:0:1}

    if [ "$(printf '%s\n' "$cur_ver" "$req_ver" | sort -V | head -n1)" != "$req_ver" ]; then
        echo "E: Detected Linux version: $cur_ver!"
        echo "E: Please upgrade to iotg kernel version newer than $req_ver!"
        return -1
    fi
}

function setup_lock_acquire() {
    # Open a file descriptor to lock file
    exec {setup_lock_fd}>$SETUP_LOCK || exit

    # Block up to 120 seconds to obtain an exclusive lock
    flock -w 120 -x $setup_lock_fd
}

function setup_lock_release() {
    test "$setup_lock_fd" || return

    # Release the lock and unset the variable
    flock -u "$setup_lock_fd"
    exec {setup_lock_fd}>&- && unset setup_lock_fd
}

function set_mem() {
    GUEST_MEM="-m $1"
}

function set_cpu() {
    GUEST_CPU_NUM="-smp cores=$1,threads=2,sockets=1"
}

function set_name() {
    GUEST_NAME="-name $1"
}

function set_disk() {
    GUEST_DISK="-drive file=$1,if=virtio,id=ubuntu_disk1,format=qcow2,cache=none"
}

function set_firmware_path() {
    GUEST_FIRMWARE="\
        -drive file=$WORK_DIR/OVMF_CODE.fd,format=raw,if=pflash,unit=0,readonly=on \
        -drive file=$1,format=raw,if=pflash,unit=1"
}

function disable_kernel_irq_chip() {
    GUEST_KIRQ_CHIP="-machine kernel_irqchip=off"
}

function set_display() {
    OIFS=$IFS IFS=',' input_arr=($1) IFS=$OIFS
    display_num=0

    # Check missing sub-param
    if [[ ${#input_arr[@]} == 0 ]]; then
       echo "E: set_display: missing sub parameters!"
       exit
    fi

    # Check sub-param from input
    for target in "${input_arr[@]}"; do
        case $target in
            max-outputs*)
                # Save max-ouputs
                GUEST_MAX_OUTPUTS=${target: -1}
                if [ $GUEST_MAX_OUTPUTS -lt $GUEST_DISPLAY_MIN ] || [ $GUEST_MAX_OUTPUTS -gt $GUEST_DISPLAY_MAX ]; then
                    echo "E: set_display: $target exceed limit, must be between $GUEST_DISPLAY_MIN to $GUEST_DISPLAY_MAX!"
                    exit
                fi
                shift
                ;;

            full-screen*)
                # Set full-screen=on
                GUEST_DISP_TYPE+=",full-screen=on"
                GUEST_FULL_SCREEN=1
                shift
                ;;

            show-fps*)
                # Set show-fps=on
                GUEST_DISP_TYPE+=",show-fps=on"
                shift
                ;;

            connectors*)
                # Save connectors settings to connectors_arr
                connectors_arr[$display_num]=$target
                ((display_num+=1))
                # Check if display number within limit
                if [ $display_num -gt $GUEST_DISPLAY_MAX ]; then
                    echo "E: set_display: $target exceed maximum display number of $GUEST_DISPLAY_MAX!"
                    exit
                elif [ $display_num -gt $GUEST_MAX_OUTPUTS ]; then
                    echo "E: set_display: $target exceed maximum output number of $GUEST_MAX_OUTPUTS!"
                    exit
                fi
                shift
                ;;

            extend-abs-mode*)
                # Set extend-abs-mode=on
                GUEST_DISP_TYPE+=",extend-abs-mode=on"
                shift
                ;;

            disable-host-input*)
                # Set input=off to disallow host HID control guest
                GUEST_DISP_TYPE+=",input=off"
                shift
                ;;

            *)
                echo "E: set_display: Invalid parameters: $target"
                exit
                ;;
        esac
    done

    for target in "${connectors_arr[@]}"; do
        # Process connectors_arr
        GUEST_DISP_TYPE+=",$target"
    done
}

function setup_sriov() {
    # Calculate hugepages needed
    required_hugepg=$(numfmt --to-unit=2Mi --from=iec ${GUEST_MEM:3})
    # Adjust guest memory to align with hugepage size
    GUEST_MEM="-m $((required_hugepg*2))M"

    # Assume that all requested hugepg are needed
    # Even though reading the following may give non-zero value
    # free_hugepg=$(</sys/kernel/mm/hugepages/hugepages-2048kB/free_hugepages)
    free_hugepg=0
    nr_hugepg=$(</sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages)
    new_nr_hugepg=$(( nr_hugepg - free_hugepg + required_hugepg ))
    echo "Setting hugepages $new_nr_hugepg"
    sudo sh -c "echo $new_nr_hugepg | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages > /dev/null"

    # Check and wait for hugepages to be allocated
    read_hugepg=0
    count=0
    while [ $((read_hugepg)) -ne $new_nr_hugepg ]
    do
        if [ $((count++)) -ge 10 ]; then
            echo "Error: insufficient memory to allocate hugepages"
            setup_lock_release
            exit
        fi
        sleep 1
        read_hugepg=$(</sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages)
        HUGEPG_ALLOC=$(( read_hugepg - nr_hugepg ))
    done

    # Detect total number of VFs
    totalvfs=$(</sys/bus/pci/devices/0000\:00\:02.0/sriov_totalvfs)

    if [ $totalvfs -eq 0 ]; then
        echo "Error: total number of supported VFs is 0"
        setup_lock_release
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
        setup_lock_release
        exit
    fi

    # Configure timeout values
    if [ $kernel_maj_ver -eq 5 ]; then
        vf_sysfs_path="/sys/class/drm/card0/iov/vf$avail/gt"
    elif [ $kernel_maj_ver -eq 6 ]; then
        vf_sysfs_path="/sys/class/drm/card0/prelim_iov/vf$avail/gt0"
    fi
    sudo sh -c "echo 500000 | sudo tee -a $vf_sysfs_path/preempt_timeout_us > /dev/null"
    sudo sh -c "echo 25 | sudo tee -a $vf_sysfs_path/exec_quantum_ms > /dev/null"
#    sudo sh -c "echo 8192 | sudo tee -a $vf_sysfs_path/contexts_quota > /dev/null"
#    sudo sh -c "echo 36 | sudo tee -a $vf_sysfs_path/doorbells_quota > /dev/null"
#    sudo sh -c "echo 529240064 | sudo tee -a $vf_sysfs_path/ggtt_quota > /dev/null"

    # Setup configuration
    GUEST_VGA_DEV="-device virtio-vga,max_outputs=$GUEST_MAX_OUTPUTS,blob=true, -device vfio-pci,host=0000:00:02.$avail, -object memory-backend-memfd,hugetlb=on,id=mem,size=${GUEST_MEM:3} -machine memory-backend=mem"
}

function cleanup_sriov() {
    # Detect number of VFs
    numvf=$(</sys/bus/pci/devices/0000\:00\:02.0/sriov_numvfs)

    do_cleanup=1
    if [ $numvf -ne 0 ]; then
        # Check that all VFs are disabled
        for (( avail=1; avail<=numvf; avail++ )); do
            is_enabled=$(</sys/bus/pci/devices/0000:00:02.$avail/enable)
            if [ $is_enabled = 1 ]; then
                do_cleanup=0
                break;
            fi
        done
    fi

    nr_hugepg=$(</sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages)
    new_nr_hugepg=$nr_hugepg

    # Determine the new hugepg value
    if [ $do_cleanup -eq 1 ]; then
        # Restore hugepg to 0
        free_hugepg=$(</sys/kernel/mm/hugepages/hugepages-2048kB/free_hugepages)
        if [ $free_hugepg -eq $nr_hugepg ]; then
            new_nr_hugepg=0
        fi
    elif [ $HUGEPG_ALLOC > 0 ]; then
        # Restore hugepg allocated to VM
        new_nr_hugepg=$(( nr_hugepg - HUGEPG_ALLOC ))
    fi

    if [ $new_nr_hugepg -ne $nr_hugepg ]; then
        echo "Restoring hugepages $new_nr_hugepg"
        sudo sh -c "echo $new_nr_hugepg | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages > /dev/null"

        # Check and wait for hugepages to be deallocated
        read_hugepg=0
        count=0
        while [ $((read_hugepg)) -ne $new_nr_hugepg ]
        do
            if [ $((count++)) -ge 10 ]; then
                echo "Error: unable to deallocate hugepages"
                setup_lock_release
                exit
            fi
            sleep 1
            read_hugepg=$(</sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages)
        done
    fi
}

function set_fwd_port() {
    OIFS=$IFS IFS=',' port_arr=($1) IFS=$OIFS
    for e in "${port_arr[@]}"; do
        if [[ $e =~ ^ssh= ]]; then
            GUEST_NET="${GUEST_NET/2222-:22/${e#*=}-:22}"
        else
            echo "E: Forward port, Invalid parameter"
            return -1;
        fi
    done
}

function enable_pwr_ctrl() {
    GUEST_PWR_CTRL=1
}

function set_pwr_ctrl() {
    qga_socket=""
    qmp_socket=""

    # Check if there is any qga and qmp power socket available
    for (( avail=0; avail<$MAX_NUM_GUEST; avail++ )); do
        qga_socket=qga-pwr-socket-$avail
        qmp_socket=qmp-pwr-socket-$avail

        if [ ! -S "/tmp/$qmp_socket" ] && [ ! -S "/tmp/$qga_socket" ]; then
            # Create qmp socket by default
            echo "Using $qmp_socket for power control qmp socket"
            GUEST_QMP_OPT="-qmp unix:/tmp/$qmp_socket,server,nowait"

            if [ $GUEST_PWR_CTRL -eq 1 ]; then
                echo "Power control is enabled for the guest!"

                # Only create qga socket when guest power control is enabled
                echo "Using $qga_socket for power control qga socket"
                GUEST_QGA_OPT="-device virtio-serial \
                               -chardev socket,path=/tmp/$qga_socket,server=on,wait=off,id=$qga_socket \
                               -device virtserialport,chardev=$qga_socket,name=org.qemu.guest_agent.0"
            fi
            break
        else
            # No power control socket available
            qga_socket=""
            qmp_socket=""
        fi
    done

    if [ ! $qga_socket ] || [ ! $qmp_socket ]; then
        echo "E: No power control socket available, maximum upto $MAX_NUM_GUEST!"
        setup_lock_release
        exit
    fi
}

function set_extra_qcmd() {
    GUEST_EXTRA_QCMD=$1
}

function set_pt_pci_vfio() {
    local PT_PCI=$1
    local unset=$2
    if [ ! -z $PT_PCI ]; then
        sudo sh -c "modprobe vfio-pci"
        local iommu_grp_dev="/sys/bus/pci/devices/$PT_PCI/iommu_group/devices/*"
        local d
        for d in $iommu_grp_dev; do
            local pci=$(basename $d)
            local vendor=$(cat $d/vendor)
            local device=$(cat $d/device)

            if [[ $unset == "unset" ]]; then
                local driver_in_use=$(basename $(realpath $d/driver))
                if [[ $driver_in_use == "vfio-pci" ]]; then
                    echo "unset PCI passthrough: $pci, $vendor:$device"
                    sudo sh -c "echo $pci > /sys/bus/pci/drivers/vfio-pci/unbind"
                    sudo sh -c "echo $vendor $device > /sys/bus/pci/drivers/vfio-pci/remove_id"
                fi
                sudo sh -c "echo $pci > /sys/bus/pci/drivers_probe"
            else
                echo "set PCI passthrough: $pci, $vendor:$device"
                [[ -d $d/driver ]] && sudo sh -c "echo $pci > $d/driver/unbind"
                sudo sh -c "echo $vendor $device > /sys/bus/pci/drivers/vfio-pci/new_id"
                GUEST_PCI_PT_ARRAY+=($PT_PCI)
            fi
        done
    fi
}

function cleanup_pt_pci() {
    local id
    for id in ${GUEST_PCI_PT_ARRAY[@]}; do
        set_pt_pci_vfio $id "unset"
    done
    unset GUEST_PCI_PT_ARRAY
}

function cleanup_pwr_ctrl() {
    # cleanup qmp power control socket on exit
    if [ -S "/tmp/$qmp_socket" ]; then
        echo "clean up qmp socket $qmp_socket"
        unlink /tmp/$qmp_socket
    fi

    # cleanup qga power control socket on exit
    if [ -S "/tmp/$qga_socket" ]; then
        echo "clean up qga socket $qga_socket"
        unlink /tmp/$qga_socket
    fi
}

# According to PCI specification, for USB controller, the prog-if field
# indicates the controller type:
#      0x00 -- UHCI
#      0x10 -- OHCI
#      0x20 -- EHCI
#      0x30 -- XHCI
#      0x80 -- Unspecified
#      0xfe -- USB Device(not a host controller)
# Refs: https://wiki.osdev.org/PCI
function is_usb_dev_udc()
{
    local pci_id=$1
    local prog_if=$(lspci -vmms $pci_id | grep ProgIf)
    if [[ ! -z $prog_if ]]; then
        if [[ ${prog_if#*:} -eq fe ]]; then
            return 0
        fi
    fi

    return -1
}

function set_pt_usb() {
    local d

    # Deny USB Thunderbolt controllers to avoid performance degrade during suspend/resume
    local USB_CONTROLLERS_DENYLIST='8086:15e9\|8086:9a13\|8086:9a1b\|8086:9a1c\|8086:9a15\|8086:9a1d'

    local USB_PCI=`lspci -D -nn | grep -i usb | grep -v "$USB_CONTROLLERS_DENYLIST" | awk '{print $1}'`
    # As BT chip is going to be passthrough to host, make the interface down in host
    if [ "$(hciconfig)" != "" ]; then
        hciconfig hci0 down
    fi
    # passthrough only USB host controller
    for d in $USB_PCI; do
        is_usb_dev_udc $d && continue

        echo "passthrough USB device: $d"
        set_pt_pci_vfio $d
        GUEST_USB_PT_DEV+=" -device vfio-pci,host=${d#*:},x-no-kvm-intx=on"
    done

    if [[ $GUEST_USB_PT_DEV != "" ]]; then
        GUEST_USB_XHCI_OPT=""
    fi
}

function set_pt_udc() {
    local d
    local UDC_PCI=$(lspci -D | grep "USB controller" | grep -o "....:..:..\..")

    # passthrough only USB device controller
    for d in $UDC_PCI; do
        is_usb_dev_udc $d || continue

        echo "passthrough UDC device: $d"
        set_pt_pci_vfio $d
        GUEST_UDC_PT_DEV+=" -device vfio-pci,host=${d#*:},x-no-kvm-intx=on"
    done
}

function set_pt_audio() {
    local d
    local AUDIO_PCI=$(lspci -D |grep -i "Audio" | grep -o "....:..:..\..")

    for d in $AUDIO_PCI; do
        echo "passthrough Audio device: $d"
        set_pt_pci_vfio $d
        GUEST_AUDIO_PT_DEV+=" -device vfio-pci,host=${d#*:},x-no-kvm-intx=on"
        GUEST_AUDIO_DEV=""
    done
}

function set_pt_eth() {
    local d
    local ETH_PCI=$(lspci -D |grep -i "Ethernet" | grep -o "....:..:..\..")

    for d in $ETH_PCI; do
        echo "passthrough Ethernet device: $d"
        set_pt_pci_vfio $d
        GUEST_ETH_PT_DEV+=" -device vfio-pci,host=${d#*:},x-no-kvm-intx=on"
        GUEST_NET=""
    done
}

function set_pt_wifi() {
    local d
    local WIFI_PCI=$(lshw -C network |grep -i "description: wireless interface" -A5 |grep "bus info" |grep -o "....:..:....")

    for d in $WIFI_PCI; do
        echo "passthrough WiFi device: $d"
        set_pt_pci_vfio $d
        GUEST_WIFI_PT_DEV+=" -device vfio-pci,host=${d#*:}"
    done
}

# Function to parse and set SPICE options
function set_spice() {
    # Check sub-param from input
    OIFS=$IFS IFS=',' input_arr=($1) IFS=$OIFS

    # Check missing sub-param
    if [[ ${#input_arr[@]} == 0 ]]; then
        echo "E: set_spice: missing sub parameters!"
        exit
    else
        # Check sub-param from input
        for target in "${input_arr[@]}"; do
            case $target in
                display=*)
                    local display="${target#*=}"
                    # validate the sub-parameters
                    if [ -z "$display" ]; then
                        echo "E: set_spice: display setting is empty!"
                        exit
                    fi
                    GUEST_SPICE_DISPLAY="${target#*=}"
                    shift
                    ;;

                port=*)
                    local port="${target#*=}"
                    # validate the sub-parameters
                    if [ -n "$port" ]; then
                        if ! [[ "$port" =~ ^[0-9]+$ ]]; then
                            echo "E: set_spice: Invalid port number: $port"
                            exit
                        fi
                    fi
                    GUEST_SPICE_PORT=$port
                    shift
                    ;;

                disable-ticketing=*)
                    local disable_ticketing="${target#*=}"
                    # validate the sub-parameters
                    if [[ "$disable_ticketing" != "on" ]] && [[ "$disable_ticketing" != "off" ]]; then
                        echo "E: set_spice: Invalid disable-ticketing value: $disable_ticketing"
                        exit
                    fi
                    GUEST_SPICED_TICKETING=$disable_ticketing
                    shift
                    ;;

                spice-audio=*)
                    local spice_audio="${target#*=}"
                    # validate the spice audio sub-parameters
                    if [[ "$spice_audio" != "on" ]] && [[ "$spice_audio" != "off" ]]; then
                        echo "E: set_spice: Invalid spice-audio value: $spice_audio"
                        exit
                    elif [[ "$spice_audio" == "on" ]]; then
                        GUEST_SPICE_AUDIO="-device ich9-intel-hda \
                                            -device hda-micro,audiodev=$GUEST_SPICE_AUDIO_NAME \
                                            -audiodev spice,id=$GUEST_SPICE_AUDIO_NAME"
                    fi

                    shift
                    ;;

                usb-redir=*)
                    local usb_redir_channel="${target#*=}"
                    # validate the sub-parameters
                    if ! [[ "$usb_redir_channel" =~ ^[0-9]+$ ]]; then
                        echo "E: set_spice: Invalid USB redir channel number: must be number."
                        exit
                    fi
                    
                    if (( usb_redir_channel > 0 && usb_redir_channel <= MAX_USB_REDIR_CHANNEL )); then
                        # set spice usb redir parameters
                        for i in $(seq $usb_redir_channel); do
                            GUEST_SPICE_USBREDIR+="-chardev spicevmc,name=usbredir,id=usbredirchardev$i \
                                                    -device usb-redir,chardev=usbredirchardev$i,id=usbredirdev$i "
                        done
                    else
                        echo "E: set_spice: Invalid USB redir channel number: must be non zero number less then max usb redirection channel number."
                    fi

                    shift
                    ;;

                *)
                    echo "E: set_spice: Invalid parameters: $target"
                    exit
                    ;;
            esac
        done
    fi

    # save all the SPICE options
    GUEST_SPICE_OPT="-spice port=$GUEST_SPICE_PORT,disable-ticketing=$GUEST_SPICE_TICKETING $GUEST_SPICE_AUDIO $GUEST_SPICE_USBREDIR"
    echo "Set spice options $GUEST_SPICE_OPT"

    # use one display for SPICE
    GUEST_MAX_OUTPUTS=1
}

# Function to parse and set Audio options
function set_audio() {
    # Check sub-param from input
    OIFS=$IFS IFS=',' input_arr=($1) IFS=$OIFS

    # Check missing sub-param
    if [[ ${#input_arr[@]} == 0 ]]; then
        echo "E: set_audio: missing sub parameters!"
        exit
    else
        # Check sub-param from input
        for target in "${input_arr[@]}"; do
            case $target in
                device=*)
                    local device="${target#*=}"
                    # validate the sub-parameters
                    if [ -z "$device" ]; then
                        echo "E: set_audio: audio device is empty!"
                        exit
                    fi
                    GUEST_AUDIO_ARCH=$device
                    shift
                    ;;

                name=*)
                    local name="${target#*=}"
                    # validate the sub-parameters
                    if [ -z "$name" ]; then
                        echo "E: set_audio: audio device name is empty!"
                        exit
                    fi
                    GUEST_AUDIO_NAME=$name
                    shift
                    ;;

                timer-period=*)
                    local period="${target#*=}"
                    # validate the sub-parameters
                    if [ -n "$period" ]; then
                        if ! [[ "$period" =~ ^[0-9]+$ ]]; then
                            echo "E: set_audio: Invalid audio time period: $period"
                            exit
                        fi
                        GUEST_AUDIO_TIMER=$period
                    else
                        echo "E: set_audio: audio time period is empty!"
                        exit
                    fi
                    shift
                    ;;

                server=*)
                    local server="${target#*=}"
                    # validate the sub-parameters
                    if [ -z "$server" ]; then
                        echo "E: set_audio: audio server is empty!"
                        exit
                    fi
                    GUEST_AUDIO_SERVER=$server
                    shift
                    ;;

                sink=*)
                    local sink="${target#*=}"
                    # validate the sub-parameters
                    if [ -z "$sink" ]; then
                        echo "E: set_audio: audio sink is empty!"
                        exit
                    fi
                    GUEST_AUDIO_SINK=$sink
                    shift
                    ;;

                *)
                    echo "E: set_audio: Invalid parameters: $target"
                    exit
                    ;;
            esac
        done
    fi

    # save all the Audio options
    GUEST_AUDIO_DEV="-device $GUEST_AUDIO_ARCH \
                     -device hda-micro,audiodev=$GUEST_AUDIO_NAME \
                     -audiodev pa,id=$GUEST_AUDIO_NAME,server=$GUEST_AUDIO_SERVER,out.name=$GUEST_AUDIO_SINK,timer-period=$GUEST_AUDIO_TIMER"
}

function cleanup() {
    setup_lock_acquire
    cleanup_pt_pci
    cleanup_pwr_ctrl
    cleanup_sriov
    setup_lock_release
}

function error() {
    echo "$BASH_SOURCE Failed at line $1: $2"
    exit
}

function launch_guest() {
    local EXE_CMD="$EMULATOR_PATH \
                   $GUEST_MEM \
                   $GUEST_CPU_NUM \
                   $GUEST_NAME \
    "

    # Check if SPICE enabled
    if [ -n "$GUEST_SPICE_OPT" ]; then
        GUEST_DISP_TYPE="-display $GUEST_SPICE_DISPLAY"
        echo "Set spice display mode to $GUEST_SPICE_DISPLAY"
    fi

    # Expand new introduced device here.
    EXE_CMD+="$GUEST_DISP_TYPE \
              $GUEST_VGA_DEV \
              $GUEST_DISK \
              $GUEST_FIRMWARE \
              $GUEST_NET \
              $GUEST_AUDIO_DEV \
              $GUEST_USB_PT_DEV \
              $GUEST_UDC_PT_DEV \
              $GUEST_AUDIO_PT_DEV \
              $GUEST_ETH_PT_DEV \
              $GUEST_WIFI_PT_DEV \
              $GUEST_KIRQ_CHIP \
              $GUEST_USB_XHCI_OPT \
              $GUEST_QGA_OPT \
              $GUEST_QMP_OPT \
              $GUEST_SPICE_OPT \
              $GUEST_STATIC_OPTION \
              $GUEST_EXTRA_QCMD \
    "

    echo $EXE_CMD
    eval $EXE_CMD
}

function show_help() {
    printf "$(basename "$0") [-h] [-m] [-c] [-n] [-d] [-f] [-p] [-e] [--passthrough-pci-usb] [--passthrough-pci-udc] [--passthrough-pci-audio] [--passthrough-pci-eth] [--passthrough-pci-wifi] [--disable-kernel-irqchip] [--display] [--enable-pwr-ctrl] [--spice] [--audio]\n"
    printf "Options:\n"
    printf "\t-h  show this help message\n"
    printf "\t-m  specify guest memory size, eg. \"-m 4G or -m 4096M\"\n"
    printf "\t-c  specify guest cpu number, eg. \"-c 4\"\n"
    printf "\t-n  specify guest vm name, eg. \"-n <guest_name>\"\n"
    printf "\t-d  specify guest virtual disk image, eg. \"-d /path/to/<guest_image>\"\n"
    printf "\t-f  specify guest firmware OVMF variable image, eg. \"-d /path/to/<ovmf_vars.fd>\"\n"
    printf "\t-p  specify host forward ports, current support ssh, eg. \"-p ssh=2222\"\n"
    printf "\t-e  specify extra qemu cmd, eg. \"-e \"-monitor stdio\"\"\n"
    printf "\t--passthrough-pci-usb passthrough USB PCI bus to guest.\n"
    printf "\t--passthrough-pci-udc passthrough USB Device Controller ie. UDC PCI bus to guest.\n"
    printf "\t--passthrough-pci-audio passthrough Audio PCI bus to guest.\n"
    printf "\t--passthrough-pci-eth passthrough Ethernet PCI bus to guest.\n"
    printf "\t--passthrough-pci-wifi passthrough WiFi PCI bus to guest.\n"
    printf "\t--disable-kernel-irqchip set kernel_irqchip=off.\n"
    printf "\t--display specify guest display connectors configuration with HPD (Hot Plug Display) feature,\n"
    printf "\t          eg. \"--display full-screen,connectors.0=HDMI-1,connectors.1=DP-1\"\n"
    printf "\t\tsub-param: max-outputs=[number of displays], set the max number of displays for guest vm, eg. \"max-outputs=2\"\n"
    printf "\t\tsub-param: full-screen, switch the guest vm display to full-screen mode.\n"
    printf "\t\tsub-param: show-fps, show fps info on guest vm primary display.\n"
    printf "\t\tsub-param: connectors.[index]=[connector name], assign a connected display connector to guest vm.\n"
    printf "\t\tsub-param: extend-abs-mode, enable extend absolute mode across all monitors.\n"
    printf "\t\tsub-param: disable-host-input, disallow host's HID devices to control the guest.\n"
    printf "\t--enable-pwr-ctrl option allow guest power control from host via qga socket.\n"
    printf "\t--spice enable SPICE feature with sub-parameters,\n"
    printf "\t          eg. \"--spice display=egl-headless,port=3002,disable-ticketing=on,spice-audio=on,usb-redir=1\"\n"
    printf "\t\tsub-param: display=[display mode], set display mode, eg. \"display=egl-headless\"\n"
    printf "\t\tsub-param: port=[spice port], assign spice port, eg. \"port=3002\"\n"
    printf "\t\tsub-param: disable-ticketing=[on|off], set disable-ticketing, eg. \"disable-ticketing=on\"\n"
    printf "\t\tsub-param: spice-audio=[on|off], set spice audio eg. \"spice-audio=on\"\n"
    printf "\t\tsub-param: usb-redir=[number of USB redir channel], set USB redirection channel number, eg. \"usb-redir=2\"\n"
    printf "\t--audio enable hda audio for guest vm with sub-parameters,\n"
    printf "\t          eg. \"--audio device=intel-hda,name=hda-audio,sink=alsa_output.pci-0000_00_1f.3.analog-stereo,timer-period=5000\"\n"
    printf "\t\tsub-param: device=[device], set audio device, eg. \"device=intel-hda\"\n"
    printf "\t\tsub-param: name=[name], set audio device name, eg. \"name=hda-audio\"\n"
    printf "\t\tsub-param: server=[audio server], set audio server, eg. \"unix:/run/user/1000/pulse/native\"\n"
    printf "\t\tsub-param: sink=[audio sink], set audio stream routing. Use \"pacmd list-sinks\" to find available audio sinks\n"
    printf "\t\tsub-param: timer-period=[period], set timer period in microseconds (us), eg. \"timer-period=5000\"\n"
}

function parse_arg() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|-\?|--help)
                show_help
                exit
                ;;

            -m)
                set_mem $2
                shift
                ;;

            -c)
                set_cpu $2
                shift
                ;;

            -n)
                set_name $2
                shift
                ;;

            -d)
                set_disk $2
                shift
                ;;

            -f)
                set_firmware_path $2
                shift
                ;;

            -p)
                set_fwd_port $2
                shift
                ;;

            -e)
                set_extra_qcmd "$2"
                shift
                ;;

            --passthrough-pci-usb)
                set_pt_usb
                ;;

            --passthrough-pci-udc)
                set_pt_udc
                ;;

            --passthrough-pci-audio)
                set_pt_audio
                ;;

            --passthrough-pci-eth)
                set_pt_eth
                ;;

            --passthrough-pci-wifi)
                set_pt_wifi
                ;;

            --disable-kernel-irqchip)
                disable_kernel_irq_chip
                ;;

            --display)
                set_display "$2"
                shift
                ;;

            --enable-pwr-ctrl)
                enable_pwr_ctrl
                ;;

            --spice)
                set_spice "$2"
                shift
                ;;

            --audio)
                set_audio "$2"
                shift
                ;;

            -?*)
                echo "Error: Invalid option $1"
                show_help
                return -1
                ;;
            *)
                echo "unknown option: $1"
                return -1
                ;;
        esac
        shift
    done
}


#-------------    main processes    -------------

trap 'setup_lock_release; cleanup' EXIT
trap 'error ${LINENO} "$BASH_COMMAND"' ERR
parse_arg "$@" || exit -1

# check
check_kernel_version || exit -1

# setup
setup_lock_acquire
setup_sriov
set_pwr_ctrl
setup_lock_release

# launch
launch_guest

echo "Done: \"$(realpath $0) $@\""
