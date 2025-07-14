<a name="win11-vm-top"></a>

# Microsoft Windows 11 VM

<!-- TABLE OF CONTENTS -->
# Table of Contents
- [Microsoft Windows 11 VM](#microsoft-windows-11-vm)
- [Table of Contents](#table-of-contents)
- [Prerequisites](#prerequisites)
- [Preparation](#preparation)
- [Installation](#installation)
  - [Create Windows VM Image](#create-windows-vm-image)
    - [Create Windows VM Image Using `qemu`](#create-windows-vm-image-using-qemu)
  - [Launch Windows VM](#launch-windows-vm)
    - [Launch VM Using `qemu`](#launch-vm-using-qemu)
    - [Launch VM Using `virsh`](#launch-vm-using-virsh)
  - [Install Windows Update and Drivers](#install-windows-update-and-drivers)
    - [Install Windows Update](#install-windows-update)
    - [Install Intel Graphics Driver](#install-intel-graphics-driver)
    - [Install SR-IOV Zero Copy Driver](#install-sr-iov-zero-copy-driver)
    - [Install Virtio Driver](#install-virtio-driver)
  - [Post Install Launch](#post-install-launch)
    - [Launch VM With `qemu`](#launch-vm-with-qemu)
    - [Launch VM With `virsh`](#launch-vm-with-virsh)
    - [Launch VM With `virt-manager`](#launch-vm-with-virt-manager)
- [Advanced Guest VM Launch](#advanced-guest-vm-launch)
  - [Launch Multiple Windows Guest VMs](#launch-multiple-windows-guest-vms)
    - [Launch Multiple Windows Guest VMs Using `qemu`](#launch-multiple-windows-guest-vms-using-qemu)
- [Reduce the Size of Guest VM](#reduce-the-size-of-guest-vm)

# Prerequisites

* Windows 11 ISO. In this example we are using Windows 11 version 23H2 (OS Build 22631.4890)
* [Intel Graphics Driver](https://www.intel.com/content/www/us/en/secure/design/confidential/software-kits/kit-details.html?kitId=843233) version 32.0.101.6314
* [SR-IOV Zero Copy Driver](https://www.intel.com/content/www/us/en/download/844242/844243/display-virtualization-drivers-for-arrow-lake-uh-arrow-lake-s.html) version 4.0.0.1797
* [Virtio Driver](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.240-1/virtio-win.iso) version 0.1.240-1

# Preparation

1. Download the Windows 11 iso image, save it as `windows.iso` and copy it to setup directory

    ```sh
    cp windows.iso /home/$USER/sriov/install_dir/
    ```

# Installation

## Create Windows VM Image

### Create Windows VM Image Using `qemu`

1. Run `install_windows.sh` to start windows vm installation

    ```sh
    # Start installing Windows guest vm
    cd /home/$USER/sriov/scripts/setup_guest/win11
    sudo ./install_windows.sh
    ```

2. Choose language and other preferences and click *Next*

    <img src=./media/winsetup1.png width="80%">

3. Select *Drive 0 Unallocated Space* and click *Next* and wait for Windows installation to succeed

    <img src=./media/winsetup2.png width="80%">

4. Shutdown the Windows guest

## Launch Windows VM

There are two options provided. Choose the corresponding launch method according to your installation method.

* [Option 1] Launch VM Using `qemu`
* [Option 2] Launch VM Using `virsh`

### Launch VM Using `qemu`

1. Run `start_windows.sh` to launch windows virtual machine

    ```sh
    cd /home/$USER/sriov/scripts/setup_guest/win11
    sudo ./start_windows.sh
    ```

### Launch VM Using `virsh`

1. Setup libvirt on host.

    *Note: Skip this step if it has been run before*

    ```sh
    cd /home/$USER/sriov/virsh_enable/host_setup/debian

    # load br_netfilter module
    sudo modprobe br_netfilter

    ./setup_libvirt.sh
    ```

    ```sh
    # reboot the system
    sudo reboot
    ```

2. Launch the windows vm

    ```sh
    cd /home/$USER/sriov/virsh_enable/

    # init windows guest vm
    ./guest_setup/idv.sh init windows11

    # launch vm
    sudo ./guest_setup/launch_multios.sh -f -d windows11 -g sriov windows11
    ```

## Install Windows Update and Drivers

### Install Windows Update

1. Install Windows update with the following steps:
    1) Open *Settings*
    2) Click *Windows Update*
    3) Click *Check for updates* and wait for the update to complete.
    4) Click *Pause for 1 week* to disable the automatic updates temporarily.

### Install Intel Graphics Driver

1. Download [Intel Graphics Driver](https://www.intel.com/content/www/us/en/secure/design/confidential/software-kits/kit-details.html?kitId=843233) from browser.
2. Use File Explorer to extract the zip file.
3. Navigate into the install folder and double click on `Installer.exe` to launch the installer.

4. Click *Begin installation*

    <img src=./media/mr2/gfxdrv1.png width="80%">
    <img src=./media/mr2/gfxdrv2.png width="80%">
    <img src=./media/mr2/gfxdrv3.png width="80%">

5. After the installation has completed, click the *Reboot Required* button to reboot.

    <img src=./media/mr2/gfxdrv4.png width="80%">

6. After reboot, launch the **Device Manager** to check the installation.

    <img src=./media/mr2/gfxdrv.png width="80%">

### Install SR-IOV Zero Copy Driver

1. Download [SR-IOV Zero Copy Driver](https://www.intel.com/content/www/us/en/download/844242/844243/display-virtualization-drivers-for-arrow-lake-uh-arrow-lake-s.html) from browser.
2. Navigate into the install folder and double click on `ZeroCopyInstaller.exe` to launch the installer.

    <img src=./media/mr2/zerocopydrv1.png width="80%">

3. Click on the *Install* button when prompted.

    <img src=./media/mr2/zerocopydrv2.png width="80%">
    <img src=./media/mr2/zerocopydrv3.png width="80%">

4. Once the driver installation completes, click *Finish* and the Windows Guest VM will reboot automatically.

    <img src=./media/mr2/zerocopydrv4.png width="80%">

5. After reboot, launch the **Device Manager** to check the installation.

    <img src=./media/mr2/zerocopydrv.png width="80%">

### Install Virtio Driver

1. Download [Virtio Driver](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.240-1/virtio-win.iso) from browser.
2. Double click the iso file in File Explorer to mount it.
3. Search for **Windows PowerShell** and run it as an administrator.
4. Navigate to the folder of the extracted files.
5. Use the following command to install VIOSerial.

    ```sh
    Start-Process msiexec.exe -Wait -ArgumentList '/i "D:\virtio-win-gt-x64.msi" ADDLOCAL="FE_network_driver,FE_balloon_driver,FE_pvpanic_driver,FE_qemupciserial_driver,FE_vioinput_driver,FE_viorng_driver,FE_vioscsi_driver,FE_vioserial_driver,FE_viostor_driver"'
    ```

6. Install QEMU guest agent in Windows VM.

    ```sh
    Start-Process msiexec.exe -ArgumentList '/i "D:\guest-agent\qemu-ga-x86_64.msi"'
    ```

### Post Install Launch

There are three options provided. Choose the corresponding launch method according to your installation method.

*Note: Option 3 should be executed after option 2*

* [Option 1] Launch VM With `qemu`
* [Option 2] Launch VM With `virsh`
* [Option 3] Launch VM With `virt-manager`

### Launch VM With `qemu`

1. Run `start_windows.sh` to launch windows virtual machine

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_guest/win11/start_windows.sh
    ```

### Launch VM With `virsh`

1. Launch the windows vm

    ```sh
    cd /home/$USER/sriov/virsh_enable/

    # init windows guest vm
    ./guest_setup/idv.sh init windows11

    # launch vm
    sudo ./guest_setup/launch_multios.sh -f -d windows11 -g sriov windows11
    ```

### Launch VM With `virt-manager`

1. Run virt-manager to launch windows virtual machine

    ```sh
    virt-manager
    ```

2. Passthrough usb device. Click *Open* button -> click *Add Hardware* and select the usb device you need -> click *Finish*

    <img src=./media/virt1.png width="80%">
    <img src=./media/virt2.png width="80%">
    <img src=./media/passthrough-usb.png width="80%">

3. Launch the windows vm. Click *Virtual Machine* -> click *Run*

# Advanced Guest VM Launch

+ Customize launch single VM

    The `start_windows.sh` script help on the host

    ```shell
    cd /home/$USER/sriov/scripts/setup_guest/win11
    sudo ./start_windows.sh -h
    ```

    Output

    ```shell
    start_windows.sh [-h] [-m] [-c] [-n] [-d] [-f] [-p] [-e] [--passthrough-pci-usb] [--passthrough-pci-udc] [--passthrough-pci-audio] [--passthrough-pci-eth] [--passthrough-pci-wifi] [--disable-kernel-irqchip] [--display] [--enable-pwr-ctrl] [--spice] [--audio]
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
                sub-param: disable-host-input, disallow host\'s HID devices to control the guest.
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

## Launch Multiple Windows Guest VMs

### Launch Multiple Windows Guest VMs Using `qemu`

1. Run the `start_all_windows.sh`, Please be patient, it will take some time

    ```shell
    # on the host
    cd /home/$USER/sriov/scripts/setup_guest/win11
    sudo ./start_all_windows.sh
    ```

# Reduce the Size of Guest VM

## Inside the VM

1. Download and Prepare Sdelete

* Obtain [Sdelete](https://learn.microsoft.com/en-us/sysinternals/downloads/sdelete) from Microsoft SysInternals and unzip the package.

2. Run Sdelete

* Execute `sdelete.exe` in Command Prompt with the -z flag on the C: drive

    ```shell
    sdelete.exe -z C:\
    ```

## On the Host

1. Backup the Disk Image

* Convert the current disk image to a backup

    ```shell
    # Please replace the <win11_image> with your actual image name
    qemu-img convert -O qcow2 <win11_image>.qcow2 <win11_image>.qcow2_backup
    ```

2. Replace the Original Disk Image

* Remove the original image and replace it with the backup

    ```shell
    # Please replace the <win11_image> with your actual image name
    rm <win11_image>.qcow2
    mv <win11_image>.qcow2_backup <win11_image>.qcow2
    ```

<p align="right">(<a href="#win11-vm-top">back to top</a>)</p>
