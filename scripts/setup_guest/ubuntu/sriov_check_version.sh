#!/bin/bash


packages=("gmmlib" "libdrm" "libva" "libva-utils" "media-driver" "mesa" "onevpl-gpu" "onevpl" "spice-client" "spice-protocol" "spice-server" "intel-igc-core" "intel-igc-opencl" "intel-level-zero-gpu" "intel-opencl-icd" "libigdgmm12")  
sudo dmesg|grep GUC

echo $guc_version
for package in "${packages[@]}"  
do  
  dpkg -l | grep "$package" | awk  '{printf "%-35s %s\n", $2, $3}'
done