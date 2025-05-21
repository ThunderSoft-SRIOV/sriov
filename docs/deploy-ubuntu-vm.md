<a name="ubuntu-vm-top"></a>
# Guest Ubuntu Virtual Machine

<!-- TABLE OF CONTENTS -->
# Table of Contents
- [Prerequisites](#prerequisites)
- [Preparation](#preparation)
- [Installation](#installation)
  - [Create Ubuntu VM Image](#create-ubuntu-vm-image)
    - [Create Ubuntu VM Image Using `qemu`](#create-ubuntu-vm-image-using-qemu)
  - [Launch Ubuntu VM](#launch-ubuntu-vm)
    - [Launch VM Using `qemu`](#launch-vm-using-qemu)
    - [Launch VM Using `virsh`](#launch-vm-using-virsh)
  - [Post Install Launch](#post-install-launch)
    - [Launch VM With `qemu`](#launch-vm-with-qemu)
    - [Launch VM With `virsh`](#launch-vm-with-virsh)
    - [Launch VM With `virt-manager`](#launch-vm-with-virt-manager)
  - [Upgrade and install Ubuntu software to the latest in the guest VM](#upgrade-and-install-ubuntu-software-to-the-latest-in-the-guest-vm)
  - [Check the installation program](#check-the-installation-program)
- [Advanced Guest VM Launch](#advanced-guest-vm-launch)
- [Reduce the Size of Guest VM](#reduce-the-size-of-guest-vm)
## Prerequisites

* [Ubuntu 22.04 ISO](https://cdimage.ubuntu.com/releases/jammy/release/inteliot/ubuntu-22.04-desktop-amd64+intel-iot.iso). In this example we are using Intel IOT Ubuntu 22.04 LTS
* [Ubuntu 24.04 ISO](https://releases.ubuntu.com/noble/ubuntu-24.04.2-desktop-amd64.iso). Ubuntu 24.04

## Preparation
### VM for ubuntu 22.04
1. Download ubuntu_22.04 iso image and save the iso file as `ubuntu.iso`

2. Copy the `ubuntu.iso` to setup directory

    ```sh
    mv ubuntu-22.04-desktop-amd64+intel-iot.iso /home/$USER/sriov/install_dir/ubuntu.iso
    ```
3. If the user environment uses a proxy, make sure environment variables such as **http_proxy**, **https_proxy**, and **no_proxy** is configured properly. Additionally, edit the file ```/etc/sudoers``` and uncomment the following line to allow passing the proxy settings to the sudo/root users

    ```shell
    sudo vi /etc/sudoers
    # Add the following line to the end of the file, save and exit
    Defaults env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"
    ```


## Installation

## Create Ubuntu VM Image

### Create Ubuntu VM Image Using `qemu`

1. Execute the following command on the host

    ```shell
    # Run install_ubuntu.sh to start Ubuntu guest installation.
    cd /home/$USER/sriov/scripts/setup_guest/ubuntu/
    chmod -R +x ./*
    sudo ./install_ubuntu.sh
    ```
    
2. Then press enter and continue boot to Ubuntu as shown on the screen below.

    <img src=./media/ubuntusetup1.png width="80%">

3. Run Ubuntu OS installation to install into the guest image and shutdown after completion, continue to execute [Upgrade and install Ubuntu software to the latest in the guest VM](#upgrade-and-install-ubuntu-software-to-the-latest-in-the-guest-vm)


## Launch Ubuntu VM

There are two options provided. Choose the corresponding launch method according to your installation method.

* [Option 1] Launch From `qemu`
* [Option 2] Launch From `virsh`

### Launch VM Using `qemu` 

1. Run `start_ubuntu.sh` to launch ubuntu virtual machine

    ```sh
    cd /home/$USER/sriov/scripts/setup_guest/ubuntu/
    sudo ./start_ubuntu.sh
    ```

### Launch VM Using `virsh`


1. Setup libvirt on host

    *Note: Skip this step if it has been run before*

    ```sh
    cd /home/$USER/sriov/virsh_enable/host_setup/debian
    
    # load br_netfilter module
    sudo modprobe br_netfilter

    ./setup_libvirt.sh
    ```

2. Reboot the system
    ```sh
    sudo reboot
    ```

3. Launch the ubuntu vm

    ```sh
    cd /home/$USER/sriov/virsh_enable/

    # init ubuntu guest vm
    ./guest_setup/idv.sh init ubuntu

    # launch vm
    sudo ./guest_setup/launch_multios.sh -f -d ubuntu -g sriov ubuntu
    ```


### Post Install Launch

There are three options provided. Choose the corresponding launch method according to your installation method.

*Note: Option 3 should be executed after option 2*

* [Option 1] Launch VM With `qemu`
* [Option 2] Launch VM With `virsh`
* [Option 3] Launch VM With `virt-manager`

### Launch VM With `qemu`

1. Run `start_ubuntu.sh` to launch ubuntu virtual machine

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_guest/ubuntu/start_ubuntu.sh
    ```

### Launch VM With `virsh`

1. Launch the ubuntu vm

    ```sh
    cd /home/$USER/sriov/virsh_enable/

    # init ubuntu guest vm
    ./guest_setup/idv.sh init ubuntu

    # launch vm
    sudo ./guest_setup/launch_multios.sh -f -d ubuntu -g sriov ubuntu
    ```
### Launch VM With `virt-manager`

1. Run `virt-manager` to launch ubuntu virtual machine
    ```shell
    virt-manager
    ```

2. Passthrough usb device. Click *Open* button -> click *Add Hardware* and select the usb device you need -> click *Finish*

    <img src=./media/ubuntu_virt.png width="80%">
    <img src=./media/ubuntu_virt_2.png width="80%">
    <img src=./media/passthrough-usb.png width="80%">

3. Launch the ubuntu vm. Click *Virtual Machine* -> click *Run*

### Upgrade and install Ubuntu software to the latest in the guest VM

1. on the host, start the ubuntu VM

    ```shell
    cd /home/$USER/sriov/scripts/setup_guest/ubuntu/
    sudo ./start_ubuntu.sh
    ```
    
2. Open a `Terminal` in the guest VM.

3. Run the command shown below to upgrade Ubuntu software to the latest in the guest VM.

    ```shell
    # Upgrade Ubuntu software
    sudo apt -y update
    sudo apt -y upgrade
    sudo apt -y install openssh-server
    ```

4. Copy the following files and directories from the /home/idvuser/ directory of the host to the /home/idvuser/ directory of the guest.

    ```shell
    # on the host
    cd /home/$USER/
    # `idvuser` is the user name of the virtual machine Ubuntu system, Please replace it yourself
    rsync -avz -e "ssh -p 2222" ./sriov/scripts/setup_guest/ubuntu idvuser@localhost:/home/idvuser/
    ```

5. Run `./setup_bsp.sh` in Ubuntu guest VM. Please be patient, it will take a few hours

    ```shell
    # in the guest
    cd /home/$USER/ubuntu/
    sudo ./setup_bsp.sh -kp 6.6-intel
    ```

6. Shut down the VM and start it using script `./start_ubuntu.sh`

    ```shell
    # on host
    cd /home/$USER/sriov/scripts/setup_guest/ubuntu/
    sudo ./start_ubuntu.sh
    ```

7. After rebooting, check if the kernel is the installed version.

    ```shell
    uname -r
    ```

    Output

    ```shell
    6.6-intel
    ```

8. [Optional] Setup OpenVINO for use with Intel GPU in guest VM. After the installation completed.

    ```shell
    # on the guest
    cd /home/$USER/ubuntu/
    ./setup_openvino.sh --neo
    ```
9. Shutdown the VM again and restart it.
    ```shell
    # on host
    cd /home/$USER/sriov/scripts/setup_guest/ubuntu/
    sudo ./start_ubuntu.sh
    ```

10. Next, Wait for successful restart of VM, The Ubuntu image Ubuntu.qcow2 is now ready to use.

## Check the installation program

### Start and Check VM

1. Start vm

    ```shell
    cd /home/$USER/sriov/scripts/setup_guest/ubuntu/
    sudo ./start_ubuntu.sh
    ```

2. Check the software version

    ```shell
    cd /home/$USER/sriov/scripts/setup_guest/ubuntu/
    sudo ./sriov_check_version.sh
    ```
    *Note: If there is a difference in package versions, it does not affect the remaining steps, just make sure the correspond package is installed successfully.*
    Example output
    ```shell
    libdrm-amdgpu1:amd64                    2.4.120-1ubuntu1-1ppa1~jammy1
    libdrm-common                           2.4.120-1ubuntu1-1ppa1~jammy1
    libdrm-dev:amd64                        2.4.120-1ubuntu1-1ppa1~jammy1
    libdrm-intel1:amd64                     2.4.120-1ubuntu1-1ppa1~jammy1
    libdrm-nouveau2:amd64                   2.4.120-1ubuntu1-1ppa1~jammy1
    libdrm-radeon1:amd64                    2.4.120-1ubuntu1-1ppa1~jammy1
    libdrm-tests                            2.4.120-1ubuntu1-1ppa1~jammy1
    libdrm2:amd64                           2.4.120-1ubuntu1-1ppa1~jammy1
    libva2:amd64                            2.21.0-1ppa1~jammy1
    libva-dev:amd64                         2.21.0-1ppa1~jammy1
    libva-drm2:amd64                        2.21.0-1ppa1~jammy1
    libva-glx2:amd64                        2.21.0-1ppa1~jammy1
    libva-wayland2:amd64                    2.21.0-1ppa1~jammy1
    libva-x11-2:amd64                       2.21.0-1ppa1~jammy1
    va-driver-all:amd64                     2.21.0-1ppa1~jammy1
    libigdgmm-dev:amd64                     22.5.0
    libigdgmm12:amd64                       22.5.0
    libvpl2                                 1:2.10.2-1ppa1~jammy3
    libvpl-dev                              1:2.10.2-1ppa1~jammy3
    libmfx-gen1.2                           24.1.5-1ppa1~jammy2
    libmfx-gen-dev                          24.1.5-1ppa1~jammy2
    intel-media-va-driver:amd64             24.1.5-1ppa1~jammy1
    intel-media-va-driver-non-free:amd64    24.1.5-1ppa1~jammy1
    libigfxcmrt-dev:amd64                   24.1.5-1ppa1~jammy1
    libigfxcmrt7:amd64                      24.1.5-1ppa1~jammy1
    libspice-client-glib-2.0-8:amd64        0.42-1ppa1~jammy4
    libspice-client-gtk-3.0-5:amd64         0.42-1ppa1~jammy4
    libspice-client-gtk-3.0-5:amd64         0.42-1ppa1~jammy4
    spice-client-gtk                        0.42-1ppa1~jammy4
    spice-client-glib-usb-acl-helper        0.42-1ppa1~jammy4
    qemu-guest-agent                        1:8.2.1+ppa1-jammy3
    libd3dadapter9-mesa:amd64               24.0.5-1ppa1~jammy2
    libd3dadapter9-mesa-dev:amd64           24.0.5-1ppa1~jammy2
    libegl-mesa0:amd64                      24.0.5-1ppa1~jammy2
    libegl1-mesa-dev:amd64                  24.0.5-1ppa1~jammy2
    libgl1-mesa-dev:amd64                   24.0.5-1ppa1~jammy2
    libgl1-mesa-dri:amd64                   24.0.5-1ppa1~jammy2
    libglapi-mesa:amd64                     24.0.5-1ppa1~jammy2
    libgles2-mesa-dev:amd64                 24.0.5-1ppa1~jammy2
    libglx-mesa0:amd64                      24.0.5-1ppa1~jammy2
    libosmesa6:amd64                        24.0.5-1ppa1~jammy2
    libosmesa6-dev:amd64                    24.0.5-1ppa1~jammy2
    libosmesa6-dev:amd64                    24.0.5-1ppa1~jammy2
    mesa-common-dev:amd64                   24.0.5-1ppa1~jammy2
    mesa-va-drivers:amd64                   24.0.5-1ppa1~jammy2
    mesa-vdpau-drivers:amd64                24.0.5-1ppa1~jammy2
    mesa-vulkan-drivers:amd64               24.0.5-1ppa1~jammy2
    ```

3. Check Ubuntu grub configuration

    ```shell
    sudo cat /etc/default/grub
    ```

    Example output
    
    ```shell
    GRUB_DEFAULT="Advanced options for Debian GNU/Linux>Debian GNU/Linux, with Linux 6.6-intel"
    .....
    GRUB_CMDLINE_LINUX="  i915.force_probe=* i915.enable_guc=0x3 i915.max_vfs=0 udmabuf.list_limit=8192 "
    ```

4. Check the loading driver

    ```shell
    glxinfo -B
    ```

    Example output
    ```
    name of display: :0
    display: :0  screen: 0
    direct rendering: Yes
    Extended renderer info (GLX_MESA_query_renderer):
        Vendor: Intel (0x8086)
        Device: Mesa Intel(R) Arc(tm) Graphics (MTL) (0x7d55)
        Version: 24.0.5
        Accelerated: yes
        Video memory: 1974MB
        Unified memory: yes
        Preferred profile: core (0x1)
        Max core profile version: 4.6
        Max compat profile version: 4.6
        Max GLES1 profile version: 1.1
        Max GLES[23] profile version: 3.2
    OpenGL vendor string: Intel
    OpenGL renderer string: Mesa Intel(R) Arc(tm) Graphics (MTL)
    OpenGL core profile version string: 4.6 (Core Profile) Mesa 24.0.5-1ppa1~jammy2 (git-7737614720)
    OpenGL core profile shading language version string: 4.60
    OpenGL core profile context flags: (none)
    OpenGL core profile profile mask: core profile

    OpenGL version string: 4.6 (Compatibility Profile) Mesa 24.0.5-1ppa1~jammy2 (git-7737614720)
    OpenGL shading language version string: 4.60
    OpenGL context flags: (none)
    OpenGL profile mask: compatibility profile

    OpenGL ES profile version string: OpenGL ES 3.2 Mesa 24.0.5-1ppa1~jammy2 (git-7737614720)
    OpenGL ES profile shading language version string: OpenGL ES GLSL ES 3.20
    ```


## Advanced Guest VM Launch

+ Customize launch single VM

    The `start_ubuntu.sh` script help on the host

    ```shell
    cd /home/$USER/sriov/scripts/setup_guest/ubuntu/
    sudo ./start_ubuntu.sh -h
    ```

    Output

    ```shell
    start_ubuntu.sh [-h] [-m] [-c] [-n] [-d] [-f] [-p] [-e] [--passthrough-pci-usb] [--passthrough-pci-udc] [--passthrough-pci-audio] [--passthrough-pci-eth] [--passthrough-pci-wifi] [--disable-kernel-irqchip] [--display] [--enable-pwr-ctrl] [--spice] [--audio]
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

+ Launch Multiple Ubuntu Guest VMs

    Run the `start_all_ubuntu.sh`, Please be patient, it will take some time
    
    ```shell
    # on the host
    cd /home/$USER/scripts/setup_guest/ubuntu/
    sudo ./start_all_ubuntu.sh
    ```
   
    After running start_all_ubuntu.sh, it will help you do the following:
   
    1. create multiple copies of `OVMF` files.
   
    2. create and setup the Ubuntu guest images. And the images will be named as `ubuntu.qcow2`, `ubuntu2.qcow2`, `ubuntu3.qcow2` and `ubuntu4.qcow2`.
   
    3. start 4 VMs
   
    Script content:
   
    ```shell
    #!/bin/bash
    # Sample script to launch multiple Ubuntu guests
    # Remember to customise the launch commands according to HW 
    setup and use case:
    # - number of guests
    # - memory allocated
    # - core allocated
    if [ ! -e ./OVMF_VARS_ubuntu2.fd ] & [ ! -e ubuntu2.qcow2 ];then
        cp -rf ./OVMF_VARS_ubuntu.fd  ./OVMF_VARS_ubuntu2.fd
        cp -rf ./ubuntu.qcow2         ./ubuntu2.qcow2
    fi 
   
    if [ ! -e ./OVMF_VARS_ubuntu2.fd ] & [ ! -e ubuntu3.qcow2 ];then
        cp -rf ./OVMF_VARS_ubuntu.fd  ./OVMF_VARS_ubuntu3.fd
        cp -rf ./ubuntu.qcow2         ./ubuntu3.qcow2
    fi 
   
    if [ ! -e ./OVMF_VARS_ubuntu2.fd ] & [ ! -e ubuntu4.qcow2 ];then
        cp -rf ./OVMF_VARS_ubuntu.fd  ./OVMF_VARS_ubuntu4.fd
        cp -rf ./ubuntu.qcow2         ./ubuntu4.qcow2
    fi 
   
    # Propagate signal to children
    trap 'trap " " SIGTERM; kill 0; wait' SIGINT SIGTERM
    # Start Ubuntu multi guests
    echo "Starting Ubuntu Guest1..."
    sudo ./start_ubuntu.sh -m 2G -c 2 -n ubuntu-vm1 &
    echo "Starting Ubuntu Guest2..."
    sudo ./start_ubuntu.sh -m 2G -c 2 -n ubuntu-vm2 -f OVMF_VARS_ubuntu2.fd -d ubuntu2.qcow2 -p ssh=2223 &
    echo "Starting Ubuntu Guest3..."
    sudo ./start_ubuntu.sh -m 2G -c 2 -n ubuntu-vm3 -f OVMF_VARS_ubuntu3.fd -d ubuntu3.qcow2 -p ssh=2224 &
    echo "Starting Ubuntu Guest4..."
    sudo ./start_ubuntu.sh -m 2G -c 2 -n ubuntu-vm4 -f OVMF_VARS_ubuntu4.fd -d ubuntu4.qcow2 -p ssh=2225 &
    wait
    ```
# Reduce the Size of Guest VM

## Inside the VM

1. Delete the sriov directory
    ```shell
    rm -rf ~/sriov
    ```

2. Create a Temporary File:

* Use the dd command to create a file filled with zeros:

    ```shell
    dd if=/dev/zero of=/mytempfile
    ```
3. Remove the Temporary File:

* Delete the file to free up space:

    ```shell
    rm -f /mytempfile
    ```
4. Next, shutdown the guest VM properly.

## On the Host

1. Backup the Disk Image

* Convert the current disk image to a backup
    
    ```shell
    # Please replace the <ubuntu_image> with your actual image name
    cd ~/sriov/install_dir/
    qemu-img convert -O qcow2 <ubuntu_image>.qcow2 <ubuntu_image>.qcow2_backup
    ```

2. Replace the Original Disk Image

* Remove the original image and replace it with the backup

    ```shell
    # Please replace the <ubuntu_image> with your actual image name
    cd ~/sriov/install_dir/
    rm <ubuntu_image>.qcow2
    mv <ubuntu_image>.qcow2_backup <ubuntu_image>.qcow2
    ```
<p align="right">(<a href="#ubuntu-vm-top">back to top</a>)</p>
