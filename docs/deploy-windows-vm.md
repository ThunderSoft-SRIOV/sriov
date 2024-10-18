<a name="win11-vm-top"></a>

# Microsoft Windows 11 VM

<!-- TABLE OF CONTENTS -->
# Table of Contents
1. [Prerequisites](#prerequisites)
1. [Installation](#installation)
    1. [Create Windows VM Image](#create-windows-vm-image)
        1. [Create Windows VM Image Using `qemu`](#create-windows-vm-image-using-qemu)
        1. [Create Windows VM Image Using `virt-manager`](#create-windows-vm-image-using-virt-manager)
        1. [Create Windows VM Image Using `virsh`](#create-windows-vm-image-using-virsh)
    1. [Install Drivers and Windows 11 update](#install-drivers-and-windows-11-update)
1. [Launch Windows VM](#launch-windows-vm)

## Prerequisites

* Windows 11 ISO.
* [Windows 11 Cumulative Update](https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/e3472ba5-22b6-46d5-8de2-db78395b3209/public/windows11.0-kb5031455-x64_d1c3bafaa9abd8c65f0354e2ea89f35470b10b65.msu)
* [Intel Graphics Driver](https://www.intel.com/content/www/us/en/secure/design/confidential/software-kits/kit-details.html?kitId=816432)
* [SR-IOV Zero Copy Driver](https://www.intel.com/content/www/us/en/download/816539/nex-display-virtualization-drivers-for-alder-lake-s-p-n-and-raptor-lake-s-p-sr-p-core-ps-amston-lake.html?cache=1708585927)
* [Virtio Driver](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.221-1/virtio-win.iso)

## Installation

## Create Windows VM Image

* [Option 1] Create Windows VM Image Using `qemu`
* [Option 2] Create Windows VM Image Using `virt-manager`
* [Option 3] Create Windows VM Image Using `virsh`

*Note: Please choose one of the installation methods*

### Create Windows VM Image Using `qemu`

1. Run `install_windows.sh` to start idv guest installation.

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_guest/win11/install_windows.sh
    ```

2. Follow Windows installation steps until installation is successful.

    <img src=./media/winsetup1.png width="80%">
    <img src=./media/winsetup2.png width="80%">

3. [Optional] Install multiple idv Guest VMs. In this example we started 4 vms.

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_guest/win11/start_multiple_windows.sh
    ```

### Create Windows VM Image Using `virt-manager`

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

5. Customize configuration. *Customize configuration before install* ->  click *Frimware* and choose **UEFI X86_64: /usr/share/OVMF/OVMF_CODE_4M.ms.fd** -> click *Apply* -> click *Begin Installation*

    <img src=./media/virtsetup5.png width="80%">
    <img src=./media/virtsetup6.png width="80%">

    Please follow the installation steps until the installation is successful.

6. [Optional] Install Multiple idv Guest VMs. Please refer to the steps 2 to 5

### Create Windows VM Image Using `virsh`

1. Run `virsh_install_windows.sh` to start idv guest installation.

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_guest/win11/virsh_install_windows.sh
    ```

2. Follow Windows installation steps until installation is successful.

    ```sh
    sudo virsh list --all
    ```

    output:
    ```sh
    Id   Name    State
    ------------------------
    1    win11   running
    ```

## Install Drivers and Windows 11 update

1. Download Intel Graphics Driver and Windows 11 update files to Windows desktop. Launch Windows 11 update installer and make sure Windows version is updated.

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

* [Option 1] Launch from `qemu`
* [Option 1] Launch from `virt-manager`
* [Option 1] Launch from `virsh`

*Note: Choose the corresponding launch method according to your installation method* 

### Launch from `qemu`

1. Run `start_windows.sh` to launch windows vm.

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_guest/win11/start_windows.sh
    ```

### Launch from `virt-manager`

1. Run `virt-manager` to launch windows vm.


    ```sh
    virt-manager
    ```

    <img src=./media/virtstart1.png width="80%">

### Launch from `virsh`

1. Run `virsh` to launch windows vm.

    ```sh
    sudo virsh start win11
    ```

<p align="right">(<a href="#win11-vm-top">back to top</a>)</p>
