#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -e

#----------------------------------      Global variable      --------------------------------------
WORK_DIR=$(pwd)
LOG_FILE="sriov_install_projects.log"
BUILD_DIR=$WORK_DIR/sriov_build
INSTALL_DIR=$WORK_DIR/sriov_install

REL_WORK_WEEK=$(date +%Y%m | cut -c 3-)

export PrefixPath=/usr
export LibPath=/usr/lib/x86_64-linux-gnu

reboot_required=0

#----------------------------------         Functions         --------------------------------------

function init_deb_name(){
    # Set debian file settings
    component="$1"
    deb_ver=$REL_WORK_WEEK
    component_name="$component"-"$deb_ver"
    deb_rev="1"
    deb_name="$component"_"$deb_ver"-"$deb_rev"_amd64
}

function add_replaces_pkg(){
    pkgs=( "$@" )
    echo "Replaces:" | sudo tee -a ./debian/control
    for pkg in ${pkgs[@]}; do
        echo " $pkg," | sudo tee -a ./debian/control
    done
}

function check_prepare_projects() {
    input="$WORK_DIR/sriov_prepare_projects.log"
    prepare_projects_success=0

    if [ -f "$input" ]; then
        while read -r line
        do
            if [[ $line == "Success" ]]; then
                prepare_projects_success=1
            fi
        done < "$input"
    fi

    if [ $prepare_projects_success == 0 ]; then
        echo "E: Please run sriov_prepare_projects.sh successfully first"
        exit
    fi
}

#----------------------------------       Main Processes      --------------------------------------

source $WORK_DIR/scripts/functions.sh

if [ $(basename $0) != "sriov_install_projects.sh" ]; then
    # change log filename to parent log
    LOG_FILE="$(basename $0 .sh).log"

    IS_SOURCED=1
fi

if [[ $IS_SOURCED -ne 1 ]]; then
    log_clean
    log_func check_prepare_projects
    log_func check_network
fi

if [ -d $BUILD_DIR ]; then
    # Clean up any existing folders
    del_existing_folder $BUILD_DIR/media
    del_existing_folder $BUILD_DIR/gstreamer
    del_existing_folder $BUILD_DIR/graphics
    del_existing_folder $BUILD_DIR/qemu-*/
    del_existing_folder $BUILD_DIR/spice
else
    mkdir -p $BUILD_DIR/
fi

if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    del_existing_folder $INSTALL_DIR/neo
    del_existing_folder $INSTALL_DIR
fi
log_func check_network

git config --global advice.detachedHead false
# media
echo "LIBVA_DRIVER_NAME=iHD" | sudo tee -a /etc/environment
echo "LIBVA_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri" | sudo tee -a /etc/environment
echo "GIT_SSL_NO_VERIFY=true" | sudo tee -a /etc/environment
source /etc/environment

git lfs install --skip-smudge


# cleanup OpenCL
set +e
sudo apt-get -y purge intel-gmmlib intel-igc-core intel-igc-opencl intel-level-zero-gpu intel-opencl-icd
sudo apt-get -y purge intel-media-va-driver-non-free libigdgmm-dev intel-media-va-driver libigdgmm12
sudo apt-get -y purge gmmlib-sriov
set -e

# OpenCL
mkdir -p $INSTALL_DIR/neo && cd $INSTALL_DIR/neo
if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.13700.14/intel-igc-core_1.0.13700.14_amd64.deb
    wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.13700.14/intel-igc-opencl_1.0.13700.14_amd64.deb
    wget https://github.com/intel/compute-runtime/releases/download/23.13.26032.30/intel-level-zero-gpu-dbgsym_1.3.26032.30_amd64.ddeb
    wget https://github.com/intel/compute-runtime/releases/download/23.13.26032.30/intel-level-zero-gpu_1.3.26032.30_amd64.deb
    wget https://github.com/intel/compute-runtime/releases/download/23.13.26032.30/intel-opencl-icd-dbgsym_23.13.26032.30_amd64.ddeb
    wget https://github.com/intel/compute-runtime/releases/download/23.13.26032.30/intel-opencl-icd_23.13.26032.30_amd64.deb
    wget https://github.com/intel/compute-runtime/releases/download/23.13.26032.30/libigdgmm12_22.3.0_amd64.deb
fi
sudo dpkg -i *.deb
cd $BUILD_DIR


# libdrm
log_func init_deb_name libdrm-sriov
if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    git clone --branch libdrm-2.4.114 --depth 1 https://gitlab.freedesktop.org/mesa/drm.git media/$component_name
    cd media/$component_name
    if [ -d "$WORK_DIR/sriov_patches/graphics/drm" ]; then
        git apply $WORK_DIR/sriov_patches/graphics/drm/*.patch
    fi
    meson build --prefix=$PrefixPath --libdir=$LibPath

    # Build and install package
    dh_make --createorig -y -s
    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
    packages=("libdrm-dev"
              "libdrm2"
              "libdrm-common"
              "libdrm-tests"
              "libdrm2-udeb"
              "libdrm-intel1"
              "libdrm-nouveau2"
              "libdrm-radeon1"
              "libdrm-omap1"
              "libdrm-freedreno1"
              "libdrm-exynos1"
              "libdrm-tegra0"
              "libdrm-amdgpu1"
              "libdrm-etnaviv1")
    add_replaces_pkg "${packages[@]}"
    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
    dpkg -i ../$deb_name.deb
    check_build_error

    # Copy debian package to installation directory
    cp ../$deb_name.deb $INSTALL_DIR
else
    # Install from debian package
    dpkg -i $INSTALL_DIR/$deb_name.deb
fi
cd $BUILD_DIR


# libva
log_func init_deb_name libva-sriov
if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    git clone --branch 2.18.0 --depth 1 https://github.com/intel/libva.git media/$component_name
    cd media/$component_name
    meson build --prefix=$PrefixPath --libdir=$LibPath

    # Build and install package
    dh_make --createorig -y -s
    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
    packages=("libva-dev"
              "libva2"
              "libva-x11-2"
              "libva-glx2"
              "libva-drm2"
              "libva-wayland2"
              "va-driver-all")
    add_replaces_pkg "${packages[@]}"
    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
    dpkg -i --ignore-depends=mesa-sriov ../$deb_name.deb
    check_build_error

    # Copy debian package to installation directory
    cp ../$deb_name.deb $INSTALL_DIR
else
    # Install from debian package
    dpkg -i --ignore-depends=mesa-sriov $INSTALL_DIR/$deb_name.deb
fi
cd $BUILD_DIR


# libva-utils
log_func init_deb_name libva-utils-sriov
if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    git clone --branch 2.18.0 --depth 1 https://github.com/intel/libva-utils.git media/$component_name
    cd media/$component_name
    meson build --prefix=$PrefixPath --libdir=$LibPath

    # Build and install package
    dh_make --createorig -y -s
    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
    packages=("vainfo")
    add_replaces_pkg "${packages[@]}"
    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
    dpkg -i ../$deb_name.deb
    check_build_error

    # Copy debian package to installation directory
    cp ../$deb_name.deb $INSTALL_DIR
else
    # Install from debian package
    dpkg -i $INSTALL_DIR/$deb_name.deb
fi
cd $BUILD_DIR


# gmmlib
log_func init_deb_name gmmlib-sriov
if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    git clone --branch intel-gmmlib-22.3.5 --depth 1 https://github.com/intel/gmmlib.git media/$component_name
    cd media/$component_name
    if [ -d "$WORK_DIR/sriov_patches/media/gmmlib" ]; then
        git apply $WORK_DIR/sriov_patches/media/gmmlib/*.patch
    fi

    # Build and install package
    dh_make --createorig -y -s
    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
    packages=("libigdgmm12"
              "libigdgmm-dev"
              "intel-gmmlib")
    add_replaces_pkg "${packages[@]}"
    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
    dpkg -i ../$deb_name.deb
    check_build_error

    # Copy debian package to installation directory
    cp ../$deb_name.deb $INSTALL_DIR
else
    # Install from debian package
    dpkg -i $INSTALL_DIR/$deb_name.deb
fi
cd $BUILD_DIR


# media-driver
log_func init_deb_name media-driver-sriov
if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    git clone --branch intel-media-23.1.0 --depth 1 https://github.com/intel/media-driver.git media/$component_name
    cd media/$component_name
    if [ -d "$WORK_DIR/sriov_patches/media/media-driver" ]; then
        git apply $WORK_DIR/sriov_patches/media/media-driver/*.patch
    fi

    # Build and install package
    dh_make --createorig -y -s
    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
    packages=("intel-media-va-driver-non-free")
    add_replaces_pkg "${packages[@]}"
    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
    dpkg -i ../$deb_name.deb
    check_build_error

    # Copy debian package to installation directory
    cp ../$deb_name.deb $INSTALL_DIR
else
    # Install from debian package
    dpkg -i $INSTALL_DIR/$deb_name.deb
fi
cd $BUILD_DIR


# Create igfx_user_feature_next.txt
echo "[config]"                        | sudo tee -a /etc/igfx_user_feature_next.txt
echo "Enable HCP Scalability Decode=0" | sudo tee -a /etc/igfx_user_feature_next.txt
echo ""                                | sudo tee -a /etc/igfx_user_feature_next.txt
echo "[report]"                        | sudo tee -a /etc/igfx_user_feature_next.txt
echo "MemNinja Counter=0"              | sudo tee -a /etc/igfx_user_feature_next.txt
echo "OCA Status=0"                    | sudo tee -a /etc/igfx_user_feature_next.txt
echo ""                                | sudo tee -a /etc/igfx_user_feature_next.txt


# onevpl-gpu
log_func init_deb_name onevpl-gpu-sriov
if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    git clone --branch intel-onevpl-22.6.5 --depth 1 https://github.com/oneapi-src/oneVPL-intel-gpu.git media/$component_name
    cd media/$component_name
    if [ -d "$WORK_DIR/sriov_patches/media/oneVPL-gpu" ]; then
        git apply $WORK_DIR/sriov_patches/media/oneVPL-gpu/*.patch
    fi

    # Build and install package
    dh_make --createorig -y -s
    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
    packages=("libmfx-gen1.2"
              "libmfx-gen-dev")
    add_replaces_pkg "${packages[@]}"
    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
    dpkg -i ../$deb_name.deb
    check_build_error

    # Copy debian package to installation directory
    cp ../$deb_name.deb $INSTALL_DIR
else
    # Install from debian package
    dpkg -i $INSTALL_DIR/$deb_name.deb
fi
cd $BUILD_DIR


# onevpl
log_func init_deb_name onevpl-sriov
if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    git clone --branch v2023.1.3 --depth 1 https://github.com/oneapi-src/oneVPL.git media/$component_name
    cd media/$component_name
    if [ -d "$WORK_DIR/sriov_patches/media/oneVPL" ]; then
        git apply $WORK_DIR/sriov_patches/media/oneVPL/*.patch
    fi

    # Build and install package
    dh_make --createorig -y -s
    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
    packages=("libvpl2"
              "libvpl-dev"
              "onevpl-tools")
    add_replaces_pkg "${packages[@]}"
    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
    dpkg -i ../$deb_name.deb
    check_build_error

    # Copy debian package to installation directory
    cp ../$deb_name.deb $INSTALL_DIR
else
    # Install from debian package
    dpkg -i $INSTALL_DIR/$deb_name.deb
fi
cd $BUILD_DIR


# gstreamer
log_func init_deb_name gstreamer-sriov
#if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    mkdir -p gstreamer
    cd gstreamer
    wget --no-check-certificate https://gstreamer.freedesktop.org/src/gstreamer/gstreamer-1.20.6.tar.xz
    tar -xvf gstreamer-1.20.6.tar.xz --strip-components 1 --one-top-level=$component_name
    cd $component_name
    meson build --prefix=$PrefixPath --libdir=$LibPath
    ninja -C build && sudo ninja -C build install
    check_build_error

#    # Build and install package
#    dh_make --createorig -y -s
#    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
#    packages=("libgstreamer1.0-0"
#              "libgstreamer1.0-dev"
#              "gstreamer1.0-tools"
#              "gir1.2-gstreamer-1.0")
#    add_replaces_pkg "${packages[@]}"
#    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
#    dpkg -i ../$deb_name.deb
#    check_build_error
#
#    # Copy debian package to installation directory
#    cp ../$deb_name.deb $INSTALL_DIR
#else
#    # Install from debian package
#    dpkg -i $INSTALL_DIR/$deb_name.deb
#fi
cd $BUILD_DIR


# gst-plugins-base
log_func init_deb_name gst-plugins-base-sriov
#if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    cd gstreamer
    wget --no-check-certificate https://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-1.20.6.tar.xz
    tar -xvf gst-plugins-base-1.20.6.tar.xz --strip-components 1 --one-top-level=$component_name
    cd $component_name
    if [ -d "$WORK_DIR/sriov_patches/gstreamer/gst-plugins-base" ]; then
        git apply $WORK_DIR/sriov_patches/gstreamer/gst-plugins-base/*.patch
    fi
    meson build --prefix=$PrefixPath --libdir=$LibPath
    ninja -C build && sudo ninja -C build install
    check_build_error

#    # Build and install package
#    dh_make --createorig -y -s
#    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
#    packages=("gstreamer1.0-plugins-base-apps"
#              "libgstreamer-plugins-base1.0-0"
#              "libgstreamer-plugins-base1.0-dev"
#              "libgstreamer-gl1.0-0"
#              "gstreamer1.0-alsa"
#              "gstreamer1.0-plugins-base"
#              "gstreamer1.0-x"
#              "gstreamer1.0-gl"
#              "gir1.2-gst-plugins-base-1.0"
#              "libgraphene-1.0-0m")
#    add_replaces_pkg "${packages[@]}"
#    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
#    dpkg -i ../$deb_name.deb
#    check_build_error
#
#    # Copy debian package to installation directory
#    cp ../$deb_name.deb $INSTALL_DIR
#else
#    # Install from debian package
#    dpkg -i $INSTALL_DIR/$deb_name.deb
#fi
cd $BUILD_DIR


# gst-plugins-good
log_func init_deb_name gst-plugins-good-sriov
#if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    cd gstreamer
    wget --no-check-certificate https://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-1.20.6.tar.xz
    tar -xvf gst-plugins-good-1.20.6.tar.xz --strip-components 1 --one-top-level=$component_name
    cd $component_name
    if [ -d "$WORK_DIR/sriov_patches/gstreamer/gst-plugins-good" ]; then
        git apply $WORK_DIR/sriov_patches/gstreamer/gst-plugins-good/*.patch
    fi
    meson build --prefix=$PrefixPath --libdir=$LibPath
    ninja -C build && sudo ninja -C build install
    check_build_error

#    # Build and install package
#    dh_make --createorig -y -s
#    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
#    packages=("gstreamer1.0-pulseaudio"
#              "gstreamer1.0-qt5"
#              "gstreamer1.0-qt6"
#              "gstreamer1.0-gtk3"
#              "gstreamer1.0-plugins-good"
#              "libgstreamer-plugins-good1.0-0"
#              "libgstreamer-plugins-good1.0-dev")
#    add_replaces_pkg "${packages[@]}"
#    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
#    dpkg -i ../$deb_name.deb
#    check_build_error
#
#    # Copy debian package to installation directory
#    cp ../$deb_name.deb $INSTALL_DIR
#else
#    # Install from debian package
#    dpkg -i $INSTALL_DIR/$deb_name.deb
#fi
cd $BUILD_DIR


# gst-plugins-bad
log_func init_deb_name gst-plugins-bad-sriov
#if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    cd gstreamer
    wget --no-check-certificate https://gstreamer.freedesktop.org/src/gst-plugins-bad/gst-plugins-bad-1.20.6.tar.xz
    tar -xvf gst-plugins-bad-1.20.6.tar.xz --strip-components 1 --one-top-level=$component_name
    cd $component_name
    if [ -d "$WORK_DIR/sriov_patches/gstreamer/gst-plugins-bad" ]; then
        git apply $WORK_DIR/sriov_patches/gstreamer/gst-plugins-bad/*.patch
    fi
    meson build --prefix=$PrefixPath --libdir=$LibPath -Dmsdk=disabled -Dmfx_api=oneVPL
    ninja -C build && sudo ninja -C build install
    check_build_error

#    # Build and install package
#    dh_make --createorig -y -s
#    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
#    packages=("gstreamer1.0-plugins-bad-apps"
#              "gstreamer1.0-plugins-bad"
#              "gstreamer1.0-opencv"
#              "gstreamer1.0-wpe"
#              "libgstreamer-plugins-bad1.0-0"
#              "libgstreamer-opencv1.0-0"
#              "libgstreamer-plugins-bad1.0-dev"
#              "gir1.2-gst-plugins-bad-1.0"
#              "gstreamer1.0-plugins-good"
#              "libgstreamer-plugins-good1.0-0")
#    add_replaces_pkg "${packages[@]}"
#    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
#    dpkg -i ../$deb_name.deb
#    check_build_error
#
#    # Copy debian package to installation directory
#    cp ../$deb_name.deb $INSTALL_DIR
#else
#    # Install from debian package
#    dpkg -i $INSTALL_DIR/$deb_name.deb
#fi
cd $BUILD_DIR


# gst-plugins-ugly
log_func init_deb_name gst-plugins-ugly-sriov
#if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    cd gstreamer
    wget --no-check-certificate https://gstreamer.freedesktop.org/src/gst-plugins-ugly/gst-plugins-ugly-1.20.6.tar.xz
    tar -xvf gst-plugins-ugly-1.20.6.tar.xz --strip-components 1 --one-top-level=$component_name
    cd $component_name
    meson build --prefix=$PrefixPath --libdir=$LibPath
    ninja -C build && sudo ninja -C build install
    check_build_error

#    # Build and install package
#    dh_make --createorig -y -s
#    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
#    packages=("gstreamer1.0-plugins-ugly")
#    add_replaces_pkg "${packages[@]}"
#    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
#    dpkg -i ../$deb_name.deb
#    check_build_error
#
#    # Copy debian package to installation directory
#    cp ../$deb_name.deb $INSTALL_DIR
#else
#    # Install from debian package
#    dpkg -i $INSTALL_DIR/$deb_name.deb
#fi
cd $BUILD_DIR


# gstreamer-vaapi
log_func init_deb_name gstreamer-vaapi-sriov
#if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    cd gstreamer
    wget --no-check-certificate https://gstreamer.freedesktop.org/src/gstreamer-vaapi/gstreamer-vaapi-1.20.6.tar.xz
    tar -xvf gstreamer-vaapi-1.20.6.tar.xz --strip-components 1 --one-top-level=$component_name
    cd $component_name
    if [ -d "$WORK_DIR/sriov_patches/gstreamer/gstreamer-vaapi" ]; then
        git apply $WORK_DIR/sriov_patches/gstreamer/gstreamer-vaapi/*.patch
    fi
    meson build --prefix=$PrefixPath --libdir=$LibPath
    ninja -C build && sudo ninja -C build install
    check_build_error

#    # Build and install package
#    dh_make --createorig -y -s
#    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
#    packages=("gstreamer1.0-vaapi")
#    add_replaces_pkg "${packages[@]}"
#    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
#    dpkg -i ../$deb_name.deb
#    check_build_error
#
#    # Copy debian package to installation directory
#    cp ../$deb_name.deb $INSTALL_DIR
#else
#    # Install from debian package
#    dpkg -i $INSTALL_DIR/$deb_name.deb
#fi
cd $BUILD_DIR


# gst-rtsp-server
log_func init_deb_name gst-rtsp-server-sriov
#if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    cd gstreamer
    wget --no-check-certificate https://gstreamer.freedesktop.org/src/gst-rtsp-server/gst-rtsp-server-1.20.6.tar.xz
    tar -xvf gst-rtsp-server-1.20.6.tar.xz --strip-components 1 --one-top-level=$component_name
    cd $component_name
    meson build --prefix=$PrefixPath --libdir=$LibPath
    ninja -C build && sudo ninja -C build install
    check_build_error

#    # Build and install package
#    dh_make --createorig -y -s
#    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
#    packages=("libgstrtspserver-1.0-dev"
#              "libgstrtspserver-1.0-0"
#              "gir1.2-gst-rtsp-server-1.0"
#              "gstreamer1.0-rtsp")
#    add_replaces_pkg "${packages[@]}"
#    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
#    dpkg -i ../$deb_name.deb
#    check_build_error
#
#    # Copy debian package to installation directory
#    cp ../$deb_name.deb $INSTALL_DIR
#else
#    # Install from debian package
#    dpkg -i $INSTALL_DIR/$deb_name.deb
#fi
cd $BUILD_DIR


# mesa
log_func init_deb_name mesa-sriov
if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    git clone --branch mesa-23.2.1 --depth 1  https://gitlab.freedesktop.org/mesa/mesa.git graphics/$component_name
    cd graphics/$component_name
    if [ -d "$WORK_DIR/sriov_patches/graphics/mesa" ]; then
        git apply $WORK_DIR/sriov_patches/graphics/mesa/*.patch
    fi
    meson build --prefix=$PrefixPath -Dgallium-drivers="swrast,iris,kmsro" -Dvulkan-drivers=intel

    # Build and install package
    dh_make --createorig -y -s
    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
    packages=("libxatracker2"
              "libxatracker-dev"
              "libd3dadapter9-mesa-dev"
              "libgbm1"
              "libgbm-dev"
              "libegl-mesa0"
              "libegl1-mesa-dev"
              "libgles2-mesa-dev"
              "libglapi-mesa"
              "libglx-mesa0"
              "libgl1-mesa-dri"
              "libgl1-mesa-dev"
              "mesa-common-dev"
              "libosmesa6"
              "libosmesa6-dev"
              "mesa-va-drivers"
              "mesa-vdpau-drivers"
              "mesa-vulkan-drivers"
              "mesa-opencl-icd"
              "mesa-drm-shim"
              "libegl-dev"
              "libgl-dev"
              "libglx-dev"
              "libgles-dev"
              "libegl1"
              "libgl1"
              "libgles1"
              "libgles2")
    add_replaces_pkg "${packages[@]}"
    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
    dpkg -i ../$deb_name.deb
    check_build_error

    # Copy debian package to installation directory
    cp ../$deb_name.deb $INSTALL_DIR
else
    # Install from debian package
    dpkg -i $INSTALL_DIR/$deb_name.deb
fi
cd $BUILD_DIR
# Create mesa_driver.sh
rm -fr /etc/profile.d/mesa_driver.sh
echo "if [ ! -e /sys/bus/pci/devices/0000\:00\:02.0/sriov_totalvfs ]; then" | sudo tee -a /etc/profile.d/mesa_driver.sh
echo "    export MESA_LOADER_DRIVER_OVERRIDE=pl111" | sudo tee -a /etc/profile.d/mesa_driver.sh
echo "else"                                         | sudo tee -a /etc/profile.d/mesa_driver.sh
echo "    export MESA_LOADER_DRIVER_OVERRIDE=iris"  | sudo tee -a /etc/profile.d/mesa_driver.sh
echo "fi"                                           | sudo tee -a /etc/profile.d/mesa_driver.sh
echo "source /etc/profile.d/mesa_driver.sh" | sudo tee -a ~/.bashrc


# Skip remaining projects for guest setup
if [[ $GUEST_SETUP == 1 ]]; then
    return
fi

# spice-protocol
log_func init_deb_name spice-protocol
if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    git clone --branch v0.14.4 --depth 1 https://gitlab.freedesktop.org/spice/spice-protocol.git spice/$component_name
    cd spice/$component_name
    meson build --prefix=$PrefixPath --libdir=$LibPath

    # Build and install package
    dh_make --createorig -y -s
    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
    packages=("libspice-protocol-dev")
    add_replaces_pkg "${packages[@]}"
    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
    dpkg -i ../$deb_name.deb
    check_build_error

    # Copy debian package to installation directory
    cp ../$deb_name.deb $INSTALL_DIR
else
    # Install from debian package
    dpkg -i $INSTALL_DIR/$deb_name.deb
fi
cd $BUILD_DIR


# spice-server
log_func init_deb_name spice-server
if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    git clone --branch v0.15.2 --depth 1 https://gitlab.freedesktop.org/spice/spice.git spice/$component_name
    cd spice/$component_name
    meson build --prefix=$PrefixPath --libdir=$LibPath

    # Build and install package
    dh_make --createorig -y -s
    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
    packages=("libspice-server1"
              "libspice-server-dev")
    add_replaces_pkg "${packages[@]}"
    sed -i "s/dh $\@/dh $\@ --buildsystem=meson/g" ./debian/rules
    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
    dpkg -i ../$deb_name.deb
    check_build_error

    # Copy debian package to installation directory
    cp ../$deb_name.deb $INSTALL_DIR
else
    # Install from debian package
    dpkg -i $INSTALL_DIR/$deb_name.deb
fi
cd $BUILD_DIR


# spice-client
log_func init_deb_name spice-client
if [[ $USE_INSTALL_FILES -ne 1 ]]; then
    # Prepare build
    git clone --branch v0.42 --depth 1 https://gitlab.freedesktop.org/spice/spice-gtk.git spice/$component_name
    cd spice/$component_name
    meson build --prefix=$PrefixPath --libdir=$LibPath

    # Build and install package
    dh_make --createorig -y -s
    sed -i "s/<insert up to 60 chars description>/SRIOV build $deb_ver for $component/g" ./debian/control
    packages=("gstreamer1.0-plugins-bad-apps"
              "gstreamer1.0-plugins-bad"
              "gstreamer1.0-opencv"
              "gstreamer1.0-wpe"
              "libgstreamer-plugins-bad1.0-0"
              "libgstreamer-opencv1.0-0"
              "libgstreamer-plugins-bad1.0-dev"
              "gir1.2-gst-plugins-bad-1.0"
              "libspice-client-glib-2.0-8"
              "libspice-client-gtk-3.0-5")
    add_replaces_pkg "${packages[@]}"
    DEB_BUILD_OPTIONS="nocheck nodoc nostrip" dpkg-buildpackage -us -uc -b
    dpkg -i ../$deb_name.deb
    check_build_error

    # Copy debian package to installation directory
    cp ../$deb_name.deb $INSTALL_DIR
else
    # Install from debian package
    dpkg -i $INSTALL_DIR/$deb_name.deb
fi
cd $BUILD_DIR


# qemu
log_func init_deb_name qemu
# if [[ $USE_PPA_FILES -ne 1 ]]; then
    # Prepare build
    git clone --branch v8.2.1 --depth 1 https://github.com/qemu/qemu.git
    cd qemu
    git apply $WORK_DIR/sriov_patches/qemu-8.2.1/*.patch
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
    # Build and install package
    cd build
    ninja && sudo ninja install
    check_build_error

# else
#     # Install from ppa
#     sudo curl -SsL -o /etc/apt/trusted.gpg.d/thundersoft-sriov.asc https://ThunderSoft-SRIOV.github.io/ppa/debian/KEY.gpg
#     sudo curl -SsL -o /etc/apt/sources.list.d/thundersoft-sriov.list https://ThunderSoft-SRIOV.github.io/ppa/debian/thundersoft-sriov.list
#     sudo apt update
#     sudo apt install -y qemu
# fi
cd $BUILD_DIR

# qemu-ovmf
sudo apt install -t bookworm-backports ovmf
cd $WORK_DIR

if [[ $IS_SOURCED -ne 1 ]]; then
    log_success
    echo "Done: \"$(realpath $0) $@\""
fi
