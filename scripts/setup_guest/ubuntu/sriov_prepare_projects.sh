#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -eE

#---------      Global variable     -------------------
WORK_DIR=$(pwd)
LOG_FILE="sriov_prepare_projects.log"
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


function check_network(){

    sudo apt-get install -y wget

    websites=("https://github.com/"
              "https://wayland.freedesktop.org/")

    set +e
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
    set -e
}


function del_existing_folder() {
    if [ -d "$1" ]; then
        echo "Deleting existing folder $1"
        rm -fr $1
    fi
}


function sriov_install_packages(){

    # List of required packages
    PACKAGES="net-tools openssh-server \
    git make autoconf libtool \
    vim libpciaccess-dev cmake \
    python3-pip  \
    llvm-15 libelf-dev bison \
    flex weston libwayland-dev libwayland-egl-backend-dev \
    xserver-xorg-dev libx11-dev libxext-dev libxdamage-dev \
    libx11-xcb-dev libxcb-glx0-dev libxcb-dri2-0-dev \
    libxcb-dri3-dev libxcb-present-dev libxshmfence-dev \
    libxxf86vm-dev libxrandr-dev libkmod-dev \
    libpixman-1-dev libcairo2-dev  libgudev-1.0-0 gtk-doc-tools \
    sshfs mesa-utils xutils-dev libunwind-dev \
    libxml2-dev doxygen xmlto cmake libpciaccess-dev \
    graphviz libjpeg-dev libwebp-dev \
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
    libcap-ng-dev libusb-1.0-0-dev nasm  \
    libseccomp-dev libtasn1-6-dev libgnutls28-dev expect gawk \
    binutils-dev fonts-freefont-ttf libsdl2-ttf-dev \
    libspice-protocol-dev libfontconfig1-dev nettle-dev \
    dmidecode libssl-dev xtightvncviewer tightvncserver x11vnc \
    uuid-runtime uml-utilities bridge-utils \
    liblzma-dev libc6-dev libegl1-mesa-dev libgbm-dev libaio-dev \
    libcap-dev libattr1-dev uuid-dev   git-lfs \
    libavutil-dev libavcodec-dev libavformat-dev gcc-mingw-w64-x86-64 screen \
    python3-mako debhelper build-essential dh-make \
    liborc-0.4-dev liblz4-dev libsasl2-dev libjson-glib-dev autoconf-archive \
    python3-pyparsing libslirp-dev libusbredirparser-dev libusbredirhost-dev \
    glslang-tools"

    if [[ $USE_INSTALL_FILES -ne 1 ]]; then
        # Download packages
        sudo apt-get install -y --download-only --reinstall ${PACKAGES}

        # Make a copy of packages
        del_existing_folder $PACKAGES_DIR
        mkdir -p $PACKAGES_DIR
        sudo cp /var/cache/apt/archives/*.deb $PACKAGES_DIR
    else
        # Copy packages to cache
        sudo cp $PACKAGES_DIR/*.deb /var/cache/apt/archives/
    fi

    # Install packages
    sudo apt-get install -y ${PACKAGES}
    cd $WORK_DIR
}


function sriov_ninja_meson-upgrade(){
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR

    #ninja
    del_existing_folder $BUILD_DIR/ninja-*/
    wget -N --no-check-certificate https://github.com/ninja-build/ninja/archive/refs/tags/v1.10.2.tar.gz
    tar -xvf v1.10.2.tar.gz
    cd ninja-*/
    python3 configure.py --bootstrap
    install -vm755 ninja /usr/bin/
    install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
    install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
    cd ..

    #meson
    del_existing_folder $BUILD_DIR/meson-*/
    wget -N --no-check-certificate https://github.com/mesonbuild/meson/releases/download/0.63.1/meson-0.63.1.tar.gz
    tar -xvf meson-0.63.1.tar.gz
    cd meson-*/
    python3 setup.py install --root=dest
    cp -rv dest/* /
    install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
    install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
    cd $WORK_DIR
}


function sriov_wayland-protocol-upgrade(){
    cd $BUILD_DIR

    del_existing_folder $BUILD_DIR/wayland-protocols-*/
    wget -N https://wayland.freedesktop.org/releases/wayland-protocols-1.25.tar.xz
    tar -xvf wayland-protocols-1.25.tar.xz
    cd wayland-protocols-1.25
    meson build --prefix=/usr
    ninja -C build
    ninja -C build install
    cd $WORK_DIR
}


function log_success(){
    echo "Success" | tee -a $WORK_DIR/$LOG_FILE
}


#-------------    main processes    -------------

if [ $(basename $0) != "sriov_prepare_projects.sh" ]; then
    # change log filename to parent log
    LOG_FILE="$(basename $0 .sh).log"

    IS_SOURCED=1
fi

if [[ $IS_SOURCED -ne 1 ]]; then
    log_clean

fi
log_func check_network
log_func sriov_install_packages
log_func sriov_ninja_meson-upgrade
log_func sriov_wayland-protocol-upgrade

if [[ $IS_SOURCED -ne 1 ]]; then
    log_success
    echo "Done: \"$(realpath $0) $@\""
fi
