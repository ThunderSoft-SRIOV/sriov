<a name="win11-vm-top"></a>

# Microsoft Windows 11 VM

<!-- TABLE OF CONTENTS -->
# Table of Contents
1. [Prerequisites](#prerequisites)
1. [Preparation](#preparation)
1. [Installation](#installation)
    1. [Create Windows VM Image](#create-windows-vm-image)
        1. [Create Windows VM Image Using `qemu`](#create-windows-vm-image-using-qemu)
        1. [Create Windows VM Image Using `virt-manager`](#create-windows-vm-image-using-virt-manager)
        1. [Create Windows VM Image Using `virsh`](#create-windows-vm-image-using-virsh) (EXPERIMENTAL)
    1. [Install Windows Update and Drivers](#install-windows-update-and-drivers)
        1. [Install Windows Update](#install-windows-update)
        1. [Install Intel Graphics Driver](#install-intel-graphics-driver)
        1. [Install SR-IOV Zero Copy Driver](#install-sr-iov-zero-copy-driver)
        1. [Install Virtio Driver](#install-virtio-driver)
1. [Launch Windows VM](#launch-windows-vm)
1. [Advanced Guest VM Launch](#advanced-guest-vm-launch)

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
* [Option 2] Create Windows VM Image Using `virt-manager`
* [Option 3] Create Windows VM Image Using `virsh` (EXPERIMENTAL)

### Create Windows VM Image Using `qemu`

1. Run `install_windows.sh` to start windows vm installation

    ```sh
    # Start guest VM to install Windows
    cd /home/$USER/sriov
    sudo ./scripts/setup_guest/win11/install_windows.sh
    ```

2. Choose language and other preferences and click *Next*

    <img src=./media/winsetup1.png width="80%">

3. Select *Drive 0 Unallocated Space* and click *Next* and wait for Windows installation to succeed

    <img src=./media/winsetup2.png width="80%">

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

5. Customize configuration. *Customize configuration before install* -> click *Finish* 

    <img src=./media/virtsetup5.png width="80%">

6. Choose firmware. Click *Firmware* and choose *UEFI X86_64: /usr/share/OVMF/OVMF_CODE_4M.ms.fd* -> click *Apply* -> click *Begin Installation*

    <img src=./media/virtsetup6.png width="80%">

7. Add Hardware. Click *Add Hardware* -> click *PCI Host Device* -> Select *0000:00:02:1 Intel Corporation Alder Lake-P Integrated Graphics Controller* -> Click *Finish*

    <img src=./media/virtsetup7.png width="80%">

8. Now you can see that the PCI device has been added. Then click *Begin Installtion* to start installing Windows guest vm.

    <img src=./media/virtsetup8.png width="80%">

### Create Windows VM Image Using `virsh` (EXPERIMENTAL)

1. Run `virsh_install_windows.sh` to start idv guest installation.

    ```sh
    # Start guest VM to install Windows
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

## Install Windows Update and Drivers

### Install Windows Update

1. Install Windows update with the following steps:
    1) Open *Settings*
    2) Click *Windows Update*
    3) Click *Check for updates* and wait for the update to complete.
    4) Click *Pause for 1 week* to disable the automatic updates temporarily.

### Install Intel Graphics Driver

1. Download [Intel Graphics Driver](https://www.intel.com/content/www/us/en/secure/design/confidential/software-kits/kit-details.html?kitId=816432) from browser.
2. Use File Explorer to extract the zip file.
3. Navigate into the install folder and double click on `installer.exe` to launch the installer.
4. Click *Begin installation*

    <img src=./media/gfxdrvinstall.png width="80%">

5. After the installation has completed, click the *Reboot Required* button to reboot.
6. After reboot, launch the **Device Manager** to check the installation.

    <img src=./media/gfxdrv.png width="80%">

### Install SR-IOV Zero Copy Driver

1. Download [SR-IOV Zero Copy Driver](https://www.intel.com/content/www/us/en/download/816539/nex-display-virtualization-drivers-for-alder-lake-s-p-n-and-raptor-lake-s-p-sr-p-core-ps-amston-lake.html?cache=1708585927) from browser.
2. Use File Explorer to extract the zip file.
3. Search for **Windows PowerShell** and run it as an administrator.
4. Enter the following command and when prompted, enter "Y/Yes" to continue.

    ```sh
    C:\> Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope CurrentUser
    ```

5. Run the command below to install the *DVServerKMD* and *DVServerUMD* device drivers. When prompted, enter "[R] Run once" to continue.

    ```sh
    C:\> .\DVInstaller.ps1
    ```

6. Once the driver installation completes, the Windows Guest VM will reboot 
automatically.
7. After reboot, launch the **Device Manager** to check the installation.

    <img src=./media/zerocopydrv.png width="80%">

### Install Virtio Driver

1. Download [Virtio Driver](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.221-1/virtio-win.iso) from browser.
2. Double click the iso file in File Explorerto mount it.
3. Search for **Windows PowerShell** and run it as an administrator.
4. Navigate to the folder of the extracted files.
5. Use the following command to install VIOSerial.

    ```sh
    D:\> pnputil.exe /add-driver .\vioserial\w11\amd64\vioser.inf /install
    ```

6. Use the following command to install qemu-guest-agent.

    ```sh
    D:\> Start-Process .\guest-agent\qemu-ga-x86_64.msi
    ```

## Launch Windows VM

There are three options provided, option 3 is in progress. Choose the corresponding launch method according to your installation method.

* [Option 1] Launch From `qemu`
* [Option 2] Launch From `virt-manager`
* [Option 3] Launch From `virsh` (EXPERIMENTAL)

### Launch From `qemu`

1. Run `start_windows.sh` to launch windows virtual machine

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_guest/win11/start_windows.sh
    ```

### Launch From `virt-manager`

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

## Advanced Guest VM Launch

+ Customize launch single VM

    The `start_windows.sh` script help on the host

    ```shell
    cd /home/$USER/sriov/
    sudo ./scripts/setup_guest/win11/start_windows.sh -h
    ```

    Output

    ```shell
    start_win.sh [-h] [-m] [-c] [-n] [-d] [-f] [-p] [-e] [--passthrough-pci-usb] [--passthrough-pci-udc] [--passthrough-pci-audio] [--passthrough-pci-eth] [--passthrough-pci-wifi] [--disable-kernel-irqchip] [--display] [--enable-pwr-ctrl] [--spice] [--audio]
    Options:
        -h  show this help message
        -m  specify guest memory size, eg. "-m 4G or -m 4096M"
        -c  specify guest cpu number, eg. "-c 4"
        -n  specify guest vm name, eg. "-n <guest_name>"
        -d  specify guest virtual disk image, eg. "-d /path/to/<guest_image>"
        -f  specify guest firmware OVMF variable image, eg. "-d /path/to/<ovmf_vars.fd>"
        -p  specify host forward ports, current support ssh, eg. "-p ssh=2222"
        -e  specify extra qemu cmd, eg. "-e "-monitor stdio""
        --passthrough-pci-usb passthrough USB PCI bus to guest.
        --passthrough-pci-udc passthrough USB Device Controller ie. UDC PCI bus to guest.
        --passthrough-pci-audio passthrough Audio PCI bus to guest.
        --passthrough-pci-eth passthrough Ethernet PCI bus to guest.
        --passthrough-pci-wifi passthrough WiFi PCI bus to guest.
        --disable-kernel-irqchip set kernel_irqchip=off.
        --display specify guest display connectors configuration with HPD (Hot Plug Display) feature,
                  eg. "--display full-screen,connectors.0=HDMI-1,connectors.1=DP-1"
                sub-param: max-outputs=[number of displays], set the max number of displays for guest vm, eg. "max-outputs=2"
                sub-param: full-screen, switch the guest vm display to full-screen mode.
                sub-param: show-fps, show fps info on the guest vm primary display.
                sub-param: connectors.[index]=[connector name], assign a connected display connector to guest vm.
                sub-param: extend-abs-mode, enable extend absolute mode across all monitors.
                sub-param: disable-host-input, disallow host's HID devices to control the guest.
        --enable-pwr-ctrl option allow guest power control from host via qga socket.
        --spice enable SPICE feature with sub-parameters,
                  eg. "--spice display=egl-headless,port=3002,disable-ticketing=on,spice-audio=on,usb-redir=1"
                sub-param: display=[display mode], set display mode, eg. "display=egl-headless"
                sub-param: port=[spice port], assign spice port, eg. "port=3002"
                sub-param: disable-ticketing=[on|off], set disable-ticketing, eg. "disable-ticketing=on"
                sub-param: spice-audio=[on|off], set spice audio eg. "spice-audio=on"
                sub-param: usb-redir=[number of USB redir channel], set USB redirection channel number, eg. "usb-redir=2"
        --audio enable hda audio for guest vm with sub-parameters,
                  eg. "--audio device=intel-hda,name=hda-audio,sink=alsa_output.pci-0000_00_1f.3.analog-stereo,timer-period=5000"
                sub-param: device=[device], set audio device, eg. "device=intel-hda"
                sub-param: name=[name], set audio device name, eg. "name=hda-audio"
                sub-param: server=[audio server], set audio server, eg. "unix:/run/user/1000/pulse/native"
                sub-param: sink=[audio sink], set audio stream routing. Use "pacmd list-sinks" to find available audio sinks
                sub-param: timer-period=[period], set timer period in microseconds (us), eg. "timer-period=5000"
        ```

+ Launch Multiple Windows Guest VMs

    Run the `start_all_windows.sh`, Please be patient, it will take some time

    ```shell
    # on the host
    cd /home/$USER/sriov
    sudo ./scripts/setup_guest/win11/start_all_windows.sh
    ```

<p align="right">(<a href="#win11-vm-top">back to top</a>)</p>
