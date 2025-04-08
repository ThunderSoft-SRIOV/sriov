#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

packages=("libdrm-amdgpu1" "libdrm-common"
          "libdrm-dev" "libdrm-intel1"
          "libdrm-nouveau2" "libdrm-radeon1"
          "libdrm-tests" "libdrm2"
          "libva2" "libva-dev" "libva-drm2"
          "libva-glx2" "libva-wayland2"
          "libva-x11-2" "va-driver-all"
          "intel-gmmlib" "libigdgmm-dev" "libigdgmm12"
          "libvpl2" "libvpl-dev"
          "libmfx-gen1.2" "libmfx-gen-dev"
          "intel-media-va-driver" "libigfxcmrt-dev" "libigfxcmrt7"
          "libspice-client-glib-2.0-8" "libspice-client-gtk-3.0-5"
          "spice-client-gtk" "spice-client-glib-usb-acl-helper"
          "qemu-system-modules-opengl" "qemu-block-extra"
          "qemu-guest-agent" "qemu-system" "qemu-system-arm"
          "qemu-system-common" "qemu-system-data" "qemu-system-gui"
          "qemu-system-mips" "qemu-system-misc" "qemu-system-ppc"
          "qemu-system-sparc" "qemu-system-x86"
          "qemu-user" "qemu-user-binfmt" "qemu-utils" "libd3dadapter9-mesa"
          "libd3dadapter9-mesa-dev" "libegl-mesa0" "libegl1-mesa-dev"
          "libgl1-mesa-dev" "libgl1-mesa-dri" "libglapi-mesa"
          "libgles2-mesa-dev" "libglx-mesa0" "libosmesa6" "libosmesa6-dev"
          "mesa-common-dev" "mesa-drm-shim" "mesa-opencl-icd" "mesa-va-drivers"
          "mesa-vdpau-drivers" "mesa-vulkan-drivers"
          )

for package in "${packages[@]}"  
do  
    dpkg -l | grep "$package" | awk  '{printf "%-35s %s\n", $2, $3}'
done
