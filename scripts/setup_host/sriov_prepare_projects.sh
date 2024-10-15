#!/bin/bash

set -eE

#----------------------------------      Global variable      --------------------------------------
WORK_DIR=$(pwd)
LOG_FILE="sriov_prepare_projects.log"
PACKAGES_DIR=$WORK_DIR/packages

#----------------------------------         Functions         --------------------------------------

function sriov_install_packages() {
    # List of required packages
    PACKAGES="net-tools openssh-server \
    git make autoconf libtool meson \
    vim libpciaccess-dev cmake \
    python3-pip python3.10 \
    llvm-15 libelf-dev bison \
    flex weston libwayland-dev libwayland-egl-backend-dev \
    xserver-xorg-dev libx11-dev libxext-dev libxdamage-dev \
    libx11-xcb-dev libxcb-glx0-dev libxcb-dri2-0-dev \
    libxcb-dri3-dev libxcb-present-dev libxshmfence-dev \
    libxxf86vm-dev libxrandr-dev libkmod-dev libdw-dev \
    libpixman-1-dev libcairo2-dev libudev-dev libgudev-1.0-0 gtk-doc-tools \
    sshfs mesa-utils xutils-dev libunwind-dev \
    libxml2-dev doxygen xmlto cmake libpciaccess-dev \
    graphviz libjpeg-dev libwebp-dev libsystemd-dev \
    libdbus-glib-1-dev libpam0g-dev freerdp2-dev \
    libxkbcommon-dev libinput-dev libxcb-shm0-dev \
    libxcb-xv0-dev libxcb-keysyms1-dev libxcb-randr0-dev \
    libxcb-composite0-dev libxcursor-dev liblcms2-dev \
    libpango1.0-dev libglfw3-dev libxcb-composite0-dev \
    libxcursor-dev libgtk-3-dev libsdl2-dev virtinst \
    virt-viewer virt-manager libspice-server-dev \
    libusb-dev libxfont-dev libxkbfile-dev libepoxy-dev \
    rpm libncurses5-dev libncursesw5-dev liblz4-tool \
    git-lfs uuid mtools python3-usb python3-pyudev \
    libjson-c-dev libfdt-dev socat bridge-utils uml-utilities \
    libcap-ng-dev libusb-1.0-0-dev nasm acpidump \
    libseccomp-dev libtasn1-6-dev libgnutls28-dev expect gawk \
    binutils-dev fonts-freefont-ttf libsdl2-ttf-dev \
    libspice-protocol-dev libfontconfig1-dev nettle-dev \
    dmidecode libssl-dev xtightvncviewer tightvncserver x11vnc \
    uuid-runtime uml-utilities bridge-utils \
    liblzma-dev libc6-dev libegl1-mesa-dev libgbm-dev libaio-dev \
    libcap-dev libattr1-dev uuid-dev acpidump iasl git-lfs \
    libavutil-dev libavcodec-dev libavformat-dev gcc-mingw-w64-x86-64 screen \
    python3-mako debhelper build-essential dh-make \
    liborc-0.4-dev liblz4-dev libsasl2-dev libjson-glib-dev autoconf-archive \
    python3-pyparsing libslirp-dev libusbredirparser-dev libusbredirhost-dev \
    glslang-tools"

    if [[ $USE_INSTALL_FILES -ne 1 ]]; then
        # Download packages
        sudo apt-get install -y --download-only -t bookworm-backports --reinstall ${PACKAGES}

        # Make a copy of packages
        del_existing_folder $PACKAGES_DIR
        mkdir -p $PACKAGES_DIR
        sudo cp /var/cache/apt/archives/*.deb $PACKAGES_DIR
    else
        # Copy packages to cache
        sudo cp $PACKAGES_DIR/*.deb /var/cache/apt/archives/
    fi

    # Install packages
    sudo apt-get install -y -t bookworm-backports ${PACKAGES}
    cd $WORK_DIR
}

#----------------------------------       Main Processes      --------------------------------------

source $WORK_DIR/scripts/functions.sh

if [ $(basename $0) != "sriov_prepare_projects.sh" ]; then
    # change log filename to parent log
    LOG_FILE="$(basename $0 .sh).log"

    IS_SOURCED=1
fi

if [[ $IS_SOURCED -ne 1 ]]; then
    log_clean
    log_func check_network
fi

log_func sriov_install_packages

if [[ $IS_SOURCED -ne 1 ]]; then
    log_success
    echo "Done: \"$(realpath $0) $@\""
fi
