#!/bin/bash

# Copyright (c) 2024 ThunderSoft Corporation.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

packages=("gmmlib"
          "libdrm"
          "libva"
          "libva-utils"
          "media-driver"
          "mesa"
          "onevpl-gpu"
          "onevpl"
          "spice-client"
          "spice-protocol"
          "spice-server"
          "intel-igc-core"
          "intel-igc-opencl"
          "intel-level-zero-gpu"
          "intel-opencl-icd"
          "libigdgmm12"
          )  

for package in "${packages[@]}"  
do  
  dpkg -l | grep "$package" | awk  '{printf "%-35s %s\n", $2, $3}'
done
