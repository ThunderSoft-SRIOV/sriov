<!-- TABLE OF CONTENTS -->
# Table of Contents
1. [Introduction](#introduction)
1. [Prerequisites](#prerequisites)
1. [Host Setup](#host-setup)
    1. [Install From Source Code](#install-from-source-code)
    1. [Install From PPA](#install-from-ppa)
1. [Virtual Machine Image Creation](#virtual-machine-image-creation)
    1. [Deploy Windows Virtual Machine](#deploy-windows-virtual-machine)
    1. [Deploy Ubuntu Virtual Machine](#deploy-ubuntu-virtual-machine)
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

  * A working [Debian 12.5 ISO](https://get.debian.org/images/archive/12.5.0/amd64/iso-dvd/debian-12.5.0-amd64-DVD-1.iso) host.

<!-- HOST SETUP -->
## Host Setup

  * [Option 1] Install From Source Code
  * [Option 2] Install From PPA

*Note: Please choose one of the installation methods*

### Preparation

1. Install `git`

    ```sh
    sudo apt update
    sudo apt install -y git
    ```

2. Clone code from github

    ```sh
    cd /home/$USER/
    git clone https://github.com/ThunderSoft-SRIOV/sriov.git
    ```

### Install From Source Code

Install and setup from source code.

1. Setup kernel

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_kernel.sh
    ```

2. Reboot the host

    ```sh
    sudo reboot
    ```

3. Setup debian after reboot

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_debian.sh
    ```

### Install From PPA

Install and setup from ppa.

1. Setup kernel

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_kernel.sh --use-ppa-files
    ```

2. Reboot the host

    ```sh
    sudo reboot
    ```

3. Setup debian after reboot

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_debian.sh --use-ppa-files
    ```

<!-- VIRTUAL MACHINE IMAGE CREATION -->
## Virtual Machine Image Creation

Follow the links below for instructions on how to setup and deploy virtual machines using this toolkit

### Deploy Windows Virtual Machine

Please refer [deploy-windows-vm](docs/deploy-windows-vm.md) for steps on creating Windows VM image.

### Deploy Ubuntu Virtual Machine

Please refer [deploy-ubuntu-vm](docs/deploy-ubuntu-vm.md) for steps on creating Ubuntu VM image.

<!-- LICENSE -->
## License

Distributed under the Apache License, Version 2.0. See *LICENSE* for more information.
