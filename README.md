<a name="readme-top"></a>

<!-- TABLE OF CONTENTS -->
# Table of Contents
1. [Introduction](#introduction)
1. [Prerequisites](#prerequisites)
1. [Preparation](#preparation)
1. [Host Setup](#host-setup)
1. [Virtual Machine Image Creation](#virtual-machine-image-creation)
    1. [Deploy Windows Virtual Machine](#deploy-windows-virtual-machine)
    1. [Deploy Ubuntu Virtual Machine](#deploy-ubuntu-virtual-machine)
1. [LICENSE](#license)

<!-- INSTRUCTION -->
# Introduction

**Intel Graphics SR-IOV Technology**

Graphics SR-IOV is Intel's latest Virtualization Technology for Graphics. Single Root I/O Virtualization (SR-IOV) defines a standard method for sharing a physical device function by partitioning the device into multiple virtual functions. Each virtual function is directly assigned to a virtual machine, thereby achieving near native performance for the virtual machine

The key benefits of Intel Graphics SR-IOV are:
  * A standard method of sharing physical GPU with virtual machines, thus allowing efficient use of GPU resource in a virtual system
  * Improved **video transcode**, **media AI analytics** and **Virtual Desktop Infrastructure (VDI)** workloads performance in virtual machine
  * Support up to 4 independent display output and 7 virtualized functions
  * Support multiple guest operating system

<!-- PREREQUISITES -->
# Prerequisites

  * A working [Debian 12.9](https://get.debian.org/images/archive/12.9.0/amd64/iso-dvd/debian-12.9.0-amd64-DVD-1.iso) host.

<!-- PREPARATION -->
# Preparation

1. Install software packages

    ```sh
    sudo apt update
    sudo apt install -y git vim curl
    ```

2. Disable automatic loading of `evbug` module

    ```shell
    sudo vim /etc/modprobe.d/*-blacklist.conf

    # Add the following line to the end of the file, save and exit
    blacklist evbug
    ```

3. If the user environment uses a proxy, make sure environment variables such as **http_proxy**, **https_proxy**, and **no_proxy** is configured properly. Additionally, edit the file ```/etc/sudoers``` and uncomment the following line to allow passing the proxy settings to the sudo/root users

    ```shell
    sudo vim /etc/sudoers

    # Add the following line to the end of the file, save and exit
    Defaults env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"
    ```

4. Clone from github

    ```sh
    cd /home/$USER/
    git clone -b mr2 https://github.com/ThunderSoft-SRIOV/sriov.git
    ```

<!-- HOST SETUP -->
# Host Setup

*Note : If you need to rebuild ppa package from source, please refer [here](docs/build_package.md) for steps on building debian packages.*

## Setup Host From PPA

Please refer [here](docs/setup_host_from_ppa.md) for steps on setting up host.


<!-- VIRTUAL MACHINE IMAGE CREATION -->
# Virtual Machine Image Creation

Follow links below for instructions on how to setup and deploy virtual machines using scripts in this repo.

## Deploy Windows Virtual Machine

Please refer [deploy-windows-vm](docs/deploy-windows-vm.md) for steps on creating Windows VM image.

## Deploy Ubuntu Virtual Machine

Please refer [deploy-ubuntu-vm](docs/deploy-ubuntu-vm.md) for steps on creating Ubuntu VM image.

<!-- LICENSE -->
# License

Distributed under the Apache License, Version 2.0. See *LICENSE* for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>
