<!-- TABLE OF CONTENTS -->
# Table of Contents
1. [Introduction](#introduction)
1. [Prerequisites](#prerequisites)
1. [Preparation](#preparation)
1. [Host Setup](#host-setup)
    1. [Setup Host From Source Code](#setup-host-from-source-code)
    1. [Setup Host From PPA](#setup-host-from-ppa)
1. [Virtual Machine Image Creation](#virtual-machine-image-creation)
    1. [Deploy Windows Virtual Machine](#deploy-windows-virtual-machine)
    1. [Deploy Ubuntu Virtual Machine](#deploy-ubuntu-virtual-machine)
1. [Enable UEFI Secure Boot](#enable-uefi-secure-boot)
1. [LICENSE](#license)

<!-- INSTRUCTION -->
## Introduction

**Intel Graphics SR-IOV Technology**

Graphics SR-IOV is Intel's latest Virtualization Technology for Graphics. Single Root I/O Virtualization (SR-IOV) defines a standard method for sharing a physical device function by partitioning the device into multiple virtual functions. Each virtual function is directly assigned to a virtual machine, thereby achieving near native performance for the virtual machine

The key benefits of Intel Graphics SR-IOV are:
  * A standard method of sharing physical GPU with virtual machines, thus allowing efficient use of GPU resource in a virtual system
  * Improved **video transcode**, **media AI analytics** and **Virtual Desktop Infrastructure (VDI)** workloads performance in virtual machine
  * Support up to 4 independent display output and 7 virtualized functions
  * Support multiple guest operating system

<!-- PREREQUISITES -->
## Prerequisites

  * A working [Debian 12.5](https://get.debian.org/images/archive/12.5.0/amd64/iso-dvd/debian-12.5.0-amd64-DVD-1.iso) host.

## Preparation

1. Install `git`

    ```sh
    sudo apt update
    sudo apt install -y git
    ```

2. Clone from github

    ```sh
    cd /home/$USER/
    git clone https://github.com/ThunderSoft-SRIOV/sriov.git
    ```

<!-- HOST SETUP -->
## Host Setup

Two installation methods are provided, please choose one of them.

  * [Option 1] Setup Host From Source Code
  * [Option 2] Setup Host From PPA

### Setup Host From Source Code

1. Setup kernel 

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_kernel.sh
    ```

2. Reboot the host

    ```sh
    sudo reboot
    ```

3. Install software after reboot

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_debian.sh
    ```
4. Modify file `/etc/modprobe.d/*-blacklist.conf`,  save and exit

    ```shell
    sudo vi /etc/modprobe.d/*-blacklist.conf

    # add the following command to the file
    blacklist evbug
    ```

### Setup Host From PPA

1. Setup kernel

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_kernel.sh --use-ppa-files
    ```

2. Reboot the host

    ```sh
    sudo reboot
    ```

3. Install software after reboot

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_debian.sh --use-ppa-files
    ```

## Enable UEFI Secure Boot

1. Create a custom MOK

    First of all you need to check if you have a key already with the following commands. 

    ```sh
    ls /var/lib/shim-signed/mok/
    ```

    If the key (consisting of the files `MOK.der`, `MOK.pem` and `MOK.priv`) does exist, then you can just use them and no need to create yourself.

    If the key does not exist, you can create your own according to the following steps:

    ```sh
    mkdir -p /var/lib/shim-signed/mok/

    cd /var/lib/shim-signed/mok/

    # Replace "/CN=My Name/" to your own information, eg. "/CN=ThunderSoft/"
    openssl req -nodes -new -x509 -newkey rsa:2048 -keyout MOK.priv -outform DER -out MOK.der -days 36500 -subj "/CN=My Name/"

    openssl x509 -inform der -in MOK.der -out MOK.pem
    ```

2. Enroll the key

    ```sh
    sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
    ```

    At next reboot, the device firmware should launch its MOK manager and prompt the user to review the new key and confirm its enrollment using the one-time password. Any kernel modules (or kernels) that have been signed with this MOK should now be loadable.

    To verify the MOK was loaded correctly:

    ```sh
    sudo mokutil --test-key /var/lib/shim-signed/mok/MOK.der
    ```

    output
    ```
    /var/lib/shim-signed/mok/MOK.der is already enrolled
    ```

3. Sign kernel with the MOK key

    *Note: First, install [sbsigntool](https://packages.debian.org/search?keywords=sbsigntool)*

    ```sh
    sbsign --key MOK.priv --cert MOK.pem "/boot/vmlinuz-6.6.32-debian-sriov" --output "/boot/vmlinuz-6.6.32-debian-sriov.tmp"
    sudo mv "/boot/vmlinuz-6.6.32-debian-sriov.tmp" "/boot/vmlinuz-6.6.32-debian-sriov"
    ```

4. Check the secure boot state

    ```sh
    sudo mokutil --sb-state
    ```

    If system returns **SecureBoot enabled** , it means that the system has booted via Secure Boot. Otherwise, you need to enable Secure Boot by following steps: 
    1) Reboot the system
    2) Enter the BIOS configuration interface
    3) Select *Security* -> *Secure Boot* -> *Enabled*
    4) Save and exit


<!-- VIRTUAL MACHINE IMAGE CREATION -->
## Virtual Machine Image Creation

Follow links below for instructions on how to setup and deploy virtual machines using scripts in this repo.

### Deploy Windows Virtual Machine

Please refer [deploy-windows-vm](docs/deploy-windows-vm.md) for steps on creating Windows VM image.

### Deploy Ubuntu Virtual Machine

Please refer [deploy-ubuntu-vm](docs/deploy-ubuntu-vm.md) for steps on creating Ubuntu VM image.

<!-- LICENSE -->
## License

Distributed under the Apache License, Version 2.0. See *LICENSE* for more information.
