<a name="win11-vm-top"></a>

# Microsoft Windows 11 VM

<!-- TABLE OF CONTENTS -->
# Table of Contents
1. [Prerequisites](#prerequisites)
1. [Preparation](#preparation)
1. [Installation](#installation)
    1. [Create Windows VM Image](#create-windows-vm-image)
        1. [Create Windows VM Image Using `qemu`](#create-windows-vm-image-using-qemu)
        1. [Create Windows VM Image Using `virt-manager`](#create-windows-vm-image-using-virt-manager) (EXPERIMENTAL)
        1. [Create Windows VM Image Using `virsh`](#create-windows-vm-image-using-virsh) (EXPERIMENTAL)
    1. [Install Drivers](#install-drivers)
1. [Launch Windows VM](#launch-windows-vm)

## Prerequisites

* Windows 11 ISO. In this example we are using Windows 11 version 23H2
* [Intel Graphics Driver](https://www.intel.com/content/www/us/en/secure/design/confidential/software-kits/kit-details.html?kitId=816432)
* [SR-IOV Zero Copy Driver](https://www.intel.com/content/www/us/en/download/816539/nex-display-virtualization-drivers-for-alder-lake-s-p-n-and-raptor-lake-s-p-sr-p-core-ps-amston-lake.html?cache=1708585927)
* [Virtio Driver](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.221-1/virtio-win.iso)

## Preparation

1. Download Windows iso image and save the iso file as `windows.iso`

2. Copy the `windows.iso` to setup directory

    ```sh
    mv windows.iso /home/$USER/sriov/scripts/setup_guest/win11/
    ```

## Installation

## Create Windows VM Image

There are three options provided, option 2 and 3 are in progress.

* [Option 1] Create Windows VM Image Using `qemu`
* [Option 2] Create Windows VM Image Using `virt-manager` (EXPERIMENTAL)
* [Option 3] Create Windows VM Image Using `virsh` (EXPERIMENTAL)

### Create Windows VM Image Using `qemu`

1. Run `install_windows.sh` to start windows vm installation

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_guest/win11/install_windows.sh
    ```

2. Choose language and other preferences and click *Next*

    <img src=./media/winsetup1.png width="80%">

3. Select *Drive 0 Unallocated Space* and click *Next* and wait for Windows installation to succeed

    <img src=./media/winsetup2.png width="80%">

4. Disable the automatic updates temporarily with the following steps: open *Setting* -> click *Update & Security* -> click *Windows Update* -> click *Pause updates for 7 days*

5. Shutdown the Windows guest

6. [Optional] Install multiple windows VMs

    *Note: Specifying the `install_multiple_windows.sh -n 2` option will install 2 virtual machines*

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_guest/win11/install_multiple_windows.sh -n 2
    ```

### Create Windows VM Image Using `virt-manager` (EXPERIMENTAL)

1. Run `virt-manager` to start idv guest installation.

    ```sh
    virt-manager
    ```

2. Choose ISO install media

    <img src=./media/virtsetup1.png width="80%">
    <img src=./media/virtsetup2.png width="80%">

3. Choose memory and cpu settings

    <img src=./media/virtsetup3.png width="80%">

4. Create a disk image for virtual machine

    <img src=./media/virtsetup4.png width="80%">

5. Customize configuration. *Customize configuration before install* -> click *Finish* 

    <img src=./media/virtsetup5.png width="80%">

6. Choose firmware. Click *Firmware* and choose **UEFI X86_64: /usr/share/OVMF/OVMF_CODE_4M.ms.fd** -> click *Apply* -> click *Begin Installation*

    <img src=./media/virtsetup6.png width="80%">

    Please follow the installation steps until the installation is successful.

7. Shutdown the Windows guest

8. [Optional] Install Multiple idv Guest VMs. Please refer to the steps 2 to 5

### Create Windows VM Image Using `virsh` (EXPERIMENTAL)

1. Run `virsh_install_windows.sh` to start idv guest installation.

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_guest/win11/virsh_install_windows.sh
    ```

2. Follow Windows installation steps until installation is successful.

    *Note: To view all guest vms, run `sudo virsh list --all`*

    ```sh
    sudo virsh list --all
    ```

    output:
    ```sh
    Id   Name    State
    ------------------------
    1    win11   running
    ```

3. Shutdown the Windows guest

## Install Drivers

1. Download Intel Graphics Driver to Windows desktop.

2. Unzip SR-IOV Zero Copy Driver installer, search for 'Windows PowerShell' and run it as an administrator. Make sure SR-IOV Zero Copy Driver is successfully installed

    ```sh
    C:\> Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope CurrentUser
    C:\> .\DVInstaller.ps1
    ```

    <img src=./media/zerocopydrv.png width="80%">

3. Unzip Intel Graphics Driver installer and navigate into the install folder and double click on installer.exe to launch the 
installer. Make sure Intel Graphics Driver is successfully installed.

    <img src=./media/gfxdrvinstall.png width="80%">
    <img src=./media/gfxdrv.png width="80%">

## Launch Windows VM

There are three options provided, option 2 and 3 are in progress. Choose the corresponding launch method according to your installation method.

* [Option 1] Launch From `qemu`
* [Option 2] Launch From `virt-manager` (EXPERIMENTAL)
* [Option 3] Launch From `virsh` (EXPERIMENTAL)

### Launch From `qemu`

1. Run `start_windows.sh` to launch windows virtual machine

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_guest/win11/start_windows.sh
    ```

2. Launch multiple virtual machines

    *Note: Specifying the `start_multiple_windows.sh -n 2` option will launch 2 virtual machines installed by `install_multiple_windows.sh`*

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_guest/win11/start_multiple_windows.sh -n 2
    ```

### Launch From `virt-manager` (EXPERIMENTAL)

1. Run `virt-manager` to launch windows virtual machine


    ```sh
    virt-manager
    ```

    <img src=./media/virtstart1.png width="80%">

### Launch From `virsh` (EXPERIMENTAL)

1. Run `virsh` to launch windows virtual machine

    ```sh
    sudo virsh start win11
    ```

<p align="right">(<a href="#win11-vm-top">back to top</a>)</p>
