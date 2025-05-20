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

function check_network() {
    websites=("https://git.kernel.org/"
              "https://github.com/")

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
}

function sriov_add_source_list() {
    # Add repository and update
    sudo echo 'deb http://deb.debian.org/debian bookworm-backports main non-free-firmware' | sudo tee -a /etc/apt/sources.list.d/debian_sriov.list
    sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D' /etc/apt/sources.list.d/debian_sriov.list
    sudo -E curl -SsL -o /etc/apt/trusted.gpg.d/thundersoft-sriov.asc https://ThunderSoft-SRIOV.github.io/debian.ppa/debian/doc/KEY.gpg
    sudo -E curl -SsL -o /etc/apt/sources.list.d/thundersoft-sriov.list https://ThunderSoft-SRIOV.github.io/debian.ppa/debian/doc/thundersoft-sriov.list
    sudo -E curl -SsL -o /etc/apt/preferences.d/thundersoft-sriov-preferred https://ThunderSoft-SRIOV.github.io/debian.ppa/debian/doc/thundersoft-sriov-preferred
    sudo apt update
    # sudo apt -t bookworm-backports upgrade
}

function sriov_install_kernel() {
    packages="linux-image-6.6-intel linux-headers-6.6-intel linux-libc-dev"
    sudo apt install -y ${packages}
}

function sriov_install_firmware() {
    # Create temporary folder
    del_existing_folder $WORK_DIR/firmware_install
    mkdir $WORK_DIR/firmware_install
    cd $WORK_DIR/firmware_install

    # Download firmware
    git clone --branch 20241210 --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git

    # Copy firmware
    sudo cp linux-firmware/i915/adlp_guc_70.bin /lib/firmware/i915
    sudo cp linux-firmware/i915/tgl_guc_70.bin /lib/firmware/i915
    sudo cp linux-firmware/i915/tgl_huc.bin /lib/firmware/i915
    sudo cp linux-firmware/i915/mtl_* /lib/firmware/i915

    # Update initramfs
    sudo update-initramfs -u -k all

    # Clean up
    cd $WORK_DIR
    del_existing_folder $WORK_DIR/firmware_install

    reboot_required=1
}

function sriov_install_packages() {
    packages="libdrm-amdgpu1 libdrm-common \
              libdrm-dev libdrm-intel1 \
              libdrm-nouveau2 libdrm-radeon1 \
              libdrm-tests libdrm2 \
              libva2 libva-dev libva-drm2 \
              libva-glx2 libva-wayland2 \
              libva-x11-2 va-driver-all \
              intel-gmmlib libigdgmm-dev libigdgmm12 \
              libvpl2 libvpl-dev \
              libmfx-gen1.2 libmfx-gen-dev \
              intel-media-va-driver libigfxcmrt-dev libigfxcmrt7 \
              libspice-client-glib-2.0-8 libspice-client-gtk-3.0-5 \
              spice-client-gtk spice-client-glib-usb-acl-helper \
              qemu-system-modules-opengl qemu-block-extra \
              qemu-guest-agent qemu-system qemu-system-arm \
              qemu-system-common qemu-system-data qemu-system-gui \
              qemu-system-mips qemu-system-misc qemu-system-ppc \
              qemu-system-sparc qemu-system-x86 \
              qemu-user qemu-user-binfmt qemu-utils libd3dadapter9-mesa \
              libd3dadapter9-mesa-dev libegl-mesa0 libegl1-mesa-dev \
              libgl1-mesa-dev libgl1-mesa-dri libglapi-mesa \
              libgles2-mesa-dev libglx-mesa0 libosmesa6 libosmesa6-dev \
              mesa-common-dev mesa-drm-shim mesa-opencl-icd mesa-va-drivers
              mesa-vdpau-drivers mesa-vulkan-drivers"

    sudo apt install -y ${packages}

    sudo apt install -t bookworm-backports ovmf

    # OpenCL
    mkdir -p $WORK_DIR/neo && cd $WORK_DIR/neo

    wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.17537.20/intel-igc-core_1.0.17537.20_amd64.deb
    wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.17537.20/intel-igc-opencl_1.0.17537.20_amd64.deb
    wget https://github.com/intel/compute-runtime/releases/download/24.35.30872.22/intel-level-zero-gpu_1.3.30872.22_amd64.deb
    wget https://github.com/intel/compute-runtime/releases/download/24.35.30872.22/intel-level-zero-gpu-legacy1_1.3.30872.22_amd64.deb
    wget https://github.com/intel/compute-runtime/releases/download/24.35.30872.22/intel-opencl-icd_24.35.30872.22_amd64.deb
    wget https://github.com/intel/compute-runtime/releases/download/24.35.30872.22/intel-opencl-icd-legacy1_24.35.30872.22_amd64.deb

    sudo dpkg -i *.deb
    cd $WORK_DIR
}

function sriov_update_grub() {
    # Retrieve installed debian-sriov kernel names
    readarray -t kernel_pkg_version < <(dpkg -l | grep "linux-headers*" | grep ^ii | grep -Po 'linux-headers-\K[^ ]*')

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

function prepare_check() {
    if command -v curl > /dev/null; then
        echo "Detected curl..."
    else
        sudo apt-get install -q -y curl
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

log_func check_network
log_func prepare_check

log_func sriov_add_source_list
log_func sriov_install_firmware
log_func sriov_install_kernel
log_func sriov_install_packages
log_func sriov_update_grub

log_success
ask_reboot

echo "Done: \"$BASH_SOURCE $@\""
