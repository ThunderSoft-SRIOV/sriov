#!/bin/bash

set -e

#--------------------------------------------         Functions       ------------------------------------------------
function install_kernel() {
    # clone source code from github
    git clone --branch lts-v6.6.32-linux-240605T051235Z --depth 1 https://github.com/intel/linux-intel-lts.git
    cd linux-intel-lts
    cp ../patches/lts-v6.6.32-linux-240605T051235Z/x86_64_defconfig ./.config
    ./scripts/config --disable DEBUG_INFO
    echo "" | make ARCH=x86_64 olddefconfig
    make ARCH=x86_64 -j$(nproc) LOCALVERSION=-debian-sriov bindeb-pkg
    sudo rm -rf ../*dbg*.deb
    sudo dpkg -i ../*.deb
    cd -
}

function install_qemu() {
    # clone source code from github
    git clone --branch v8.2.1 --depth 1 https://github.com/qemu/qemu.git
    cd qemu
    git apply ../patches/qemu-8.2.1/*.patch
    ./configure --target-list=x86_64-softmmu \
                --enable-debug \
                --disable-docs \
                --disable-virglrenderer \
                --prefix=/usr \
                --enable-virtfs \
                --enable-libusb \
                --disable-debug-tcg \
                --enable-spice \
                --enable-usb-redir \
                --enable-gtk \
                --enable-slirp

    cd build
    ninja && ninja install
    cd -
}

install_kernel
install_qemu
