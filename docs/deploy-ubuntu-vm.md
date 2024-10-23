# Guest Ubuntu Virtual Machine

# Table of Contents
1. [Prerequisites](#prerequisites)
1. [Preparation](#preparation)
1. [Installation](#installation)
    1. [Create Ubuntu VM Image](#create-ubuntu-vm-image)
        1. [Create Ubuntu VM Image Using `qemu`](#create-ubuntu-vm-image-using-qemu)
        1. [Create Ubuntu VM Image Using `virt-manager`](#create-ubuntu-vm-image-using-virt-manager) (EXPERIMENTAL)
        1. [Create Ubuntu VM Image Using `virsh`](#create-ubuntu-vm-image-using-virsh) (EXPERIMENTAL)
    1. [Upgrade and install Ubuntu software to the latest in the guest VM](#upgrade-and-install-ubuntu-software-to-the-latest-in-the-guest-vm)
1. [Check the installation program](#check-the-installation-program)
1. [Launch Ubuntu VM](#launch-ubuntu-vm)
1. [Advanced Guest VM Launch](#advanced-guest-vm-launch)

## Prerequisites

* [Ubuntu 22.04 ISO](https://cdimage.ubuntu.com/releases/jammy/release/inteliot/ubuntu-22.04-desktop-amd64+intel-iot.iso). In this example we are using Intel IOT Ubuntu 22.04 LTS

## Preparation

1. Download ubuntu iso image and save the iso file as `ubuntu.iso`

2. Copy the `ubuntu.iso` to setup directory

    ```sh
    mv ubuntu-22.04-desktop-amd64+intel-iot.iso ./sriov/scripts/setup_guest/ubuntu/ubuntu.iso
    ```

## Installation

## Create Ubuntu VM Image

There are three options provided, option 2 and 3 are in progress.

* [Option 1] Create Ubuntu VM Image Using `qemu`
* [Option 2] Create Ubuntu VM Image Using `virt-manager` (EXPERIMENTAL)
* [Option 3] Create Ubuntu VM Image Using `virsh` (EXPERIMENTAL)

### Create Ubuntu VM Image Using `qemu`

1. Execute the following command in the host

    ```shell
    # Run install_ubuntu.sh to start Ubuntu guest installation.
    cd /home/$USER/sriov/scripts/setup_guest/ubuntu/
    chmod -R +x ./*
    sudo ./install_ubuntu.sh
    ```
    
2. Then press enter and continue boot to Ubuntu as shown in the screen below.

    <img src=./media/ubuntusetup1.png width="80%">

3. Run Ubuntu OS installation to install into the guest image and shutdown after completion, continue to execute [Upgrade and install Ubuntu software to the latest in the guest VM](#upgrade-and-install-ubuntu-software-to-the-latest-in-the-guest-vm)

### Create Ubuntu VM Image Using `virt-manager`  (EXPERIMENTAL)

1. Run `virt-manager` to start Ubuntu guest installation in the host.

    ```shell
    virt-manager
    ```

2. Select image and follow Ubuntu installation steps until installation is successful.

    <img src=./media/setup_ubuntu1.png width="80%">
    <img src=./media/virtsetup3.png width="80%">
    <img src=./media/virtsetup4.png width="80%">
    <img src=./media/setup_ubuntu2.png width="80%">

3. After successful installation,  shutdown the virtual machine, continue to execute [Upgrade and install Ubuntu software to the latest in the guest VM](#upgrade-and-install-ubuntu-software-to-the-latest-in-the-guest-vm)

### Create Ubuntu VM Image Using `virsh`  (EXPERIMENTAL)

1. Run `virsh_install_ubuntu.sh` to start ubuntu guest installation.

    ```sh
    # in the host
    cd /home/$USER/sriov/scripts/setup_guest/ubuntu/
    sudo ./virsh_install_ubuntu.sh
    ```

2. Follow ubuntu installation steps until installation is successful.

    ```sh
    sudo virsh list --all
    ```

    Output
    ```sh
    Id   Name    State
    ------------------------
    1    ubuntu   running
    ```

3. After successful installation,  shutdown the virtual machine, continue to execute [Upgrade and install Ubuntu software to the latest in the guest VM](#upgrade-and-install-ubuntu-software-to-the-latest-in-the-guest-vm)

### Upgrade and install Ubuntu software to the latest in the guest VM

1. In the host, start the ubuntu VM

    ```shell
    # host start ubuntu
    cd /home/$USER/sriov/scripts/setup_guest/ubuntu/
    sudo ./start_ubuntu.sh
    ```

2. Open a `Terminal` within the guest VM.

3. Run the command shown below to upgrade Ubuntu software to the latest in the guest VM.

    ```shell
    # Upgrade Ubuntu software
    sudo apt -y update
    sudo apt -y upgrade
    sudo apt -y install openssh-server
    ```

4. Copy the following files and directories from the /home/idvuser/ directory of the host to the /home/guest/ directory of the guest.

    ```shell
    # in the host
    cd /home/$USER/
    # `idvuser` is the user name of the virtual machine Ubuntu system, Please replace it yourself
    rsync -avz -e "ssh -p 2222" --exclude '*.qcow2' --exclude '*.iso' ./sriov idvuser@localhost:/home/idvuser/
    ```

5. Run sriov_setup_kernel.sh in Ubuntu guest VM.

    ```shell
    # in the guest
    cd /home/$USER/
    cp -rf ./sriov/sriov_patches ./sriov/scripts/setup_guest/ubuntu/

    # This will install kernel and firmware, and update grub
    cd ./sriov/scripts/setup_guest/ubuntu/
    sudo ./sriov_prepare_projects.sh
    sudo ./sriov_setup_ubuntu_guest_kernel.sh
    ```

6. Reboot the system.

    ```shell
    sudo reboot
    ```

7. After rebooting, check if the kernel is the installed version.

    ```shell
    uname -r
    ```

    Output

    ```shell
    6.6.32-ubuntu-sriov
    ```

8. Prepare and generate the install files in Ubuntu guest VM.

    ```shell
    # in the guest
    cd /home/$USER/sriov/scripts/setup_guest/ubuntu/
    sudo .sriov_install_projects.sh
    
    # After executing the above command, 3 folders will be generated
    # ./sriov/scripts/setup_guest/ubuntu/packages
    # ./sriov/scripts/setup_guest/ubuntu/sriov_install
    # ./sriov/scripts/setup_guest/ubuntu/sriov_build
    ```

9. Run configure_ubuntu_guest.sh in Ubuntu guest VM.

    ```shell
    # in the guest
    # This will install userspace libraries and tools
    cd /home/$USER/sriov/scripts/setup_guest/ubuntu/
    sudo ./configure_ubuntu_guest.sh
    ```

10. After the installation completed, reboot the guest when prompted.

11. Next, shutdown the guest properly. The Ubuntu image `Ubuntu.qcow2` is now ready to use.

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

    Example output
    ```shell
    gmmlib-sriov                        2405-1
    libdrm-amdgpu1:amd64                2.4.113-2~ubuntu0.22.04.1
    libdrm-common                       2.4.113-2~ubuntu0.22.04.1
    libdrm-dev:amd64                    2.4.113-2~ubuntu0.22.04.1
    libdrm-intel1:amd64                 2.4.113-2~ubuntu0.22.04.1
    libdrm-nouveau2:amd64               2.4.113-2~ubuntu0.22.04.1
    libdrm-radeon1:amd64                2.4.113-2~ubuntu0.22.04.1
    libdrm-sriov                        2405-1
    libdrm2:amd64                       2.4.113-2~ubuntu0.22.04.1
    libva-drm2:amd64                    2.14.0-1
    libva-sriov                         2405-1
    libva-utils-sriov                   2405-1
    libva-wayland2:amd64                2.14.0-1
    libva-x11-2:amd64                   2.14.0-1
    libva2:amd64                        2.14.0-1
    libvariable-magic-perl              0.62-1build5
    libva-utils-sriov                   2405-1
    media-driver-sriov                  2405-1
    libegl-mesa0:amd64                  23.2.1-1ubuntu3.1~22.04.2
    libegl1-mesa:amd64                  23.0.4-0ubuntu1~22.04.1
    libegl1-mesa-dev:amd64              23.2.1-1ubuntu3.1~22.04.2
    libgl1-mesa-dri:amd64               23.2.1-1ubuntu3.1~22.04.2
    libglapi-mesa:amd64                 23.2.1-1ubuntu3.1~22.04.2
    libglu1-mesa:amd64                  9.0.2-1
    libglu1-mesa-dev:amd64              9.0.2-1
    libglx-mesa0:amd64                  23.2.1-1ubuntu3.1~22.04.2
    mesa-common-dev:amd64               23.2.1-1ubuntu3.1~22.04.2
    mesa-sriov                          2405-1
    mesa-utils                          8.4.0-1ubuntu1
    mesa-utils-bin:amd64                8.4.0-1ubuntu1
    mesa-va-drivers:amd64               23.2.1-1ubuntu3.1~22.04.2
    mesa-vdpau-drivers:amd64            23.2.1-1ubuntu3.1~22.04.2
    mesa-vulkan-drivers:amd64           22.2.5-0ubuntu0.1~22.04.1
    onevpl-gpu-sriov                    2405-1
    onevpl-gpu-sriov                    2405-1
    onevpl-sriov                        2405-1
    libspice-client-glib-2.0-8:amd64    0.39-3ubuntu1
    libspice-client-gtk-3.0-5:amd64     0.39-3ubuntu1
    spice-client-glib-usb-acl-helper    0.39-3ubuntu1
    libspice-protocol-dev               0.14.3-1
    libspice-server-dev:amd64           0.15.0-2ubuntu4
    libspice-server1:amd64              0.15.0-2ubuntu4
    intel-igc-core                      1.0.13700.14
    intel-igc-opencl                    1.0.13700.14
    intel-level-zero-gpu                1.3.26032.30
    intel-opencl-icd                    23.13.26032.30
    libigdgmm12:amd64                   22.3.0
    ```

3. Check Ubuntu grub configuration

    ```shell
    sudo cat /etc/default/grub
    ```

    Example output
    
    ```shell
    GRUB_DEFAULT="Advanced options for Debian GNU/Linux>Debian GNU/Linux, with Linux 6.6.32-ubuntu"
    .....
    GRUB_CMDLINE_LINUX_DEFAULT="quiet console=tty0,115200n8 intel_iommu=on iommu=soft vt_handoff=7"
    GRUB_CMDLINE_LINUX="splash i915.enable_guc=3 i915.force_probe=* udmabuf.list_limit=8192"
    
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
        Device: Mesa Intel(R) Graphics (ADL GT2) (0x46a6)
        Version: 23.2.1
        Accelerated: yes
        Video memory: 1974MB
        Unified memory: yes
        Preferred profile: core (0x1)
        Max core profile version: 4.6
        Max compat profile version: 4.6
        Max GLES1 profile version: 1.1
        Max GLES[23] profile version: 3.2
    OpenGL vendor string: Intel
    OpenGL renderer string: Mesa Intel(R) Graphics (ADL GT2)
    OpenGL core profile version string: 4.6 (Core Profile) Mesa 23.2.1 (git-49a47f187e)
    OpenGL core profile shading language version string: 4.60
    OpenGL core profile context flags: (none)
    OpenGL core profile profile mask: core profile
    
    OpenGL version string: 4.6 (Compatibility Profile) Mesa 23.2.1 (git-49a47f187e)
    OpenGL shading language version string: 4.60
    OpenGL context flags: (none)
    OpenGL profile mask: compatibility profile
    
    OpenGL ES profile version string: OpenGL ES 3.2 Mesa 23.2.1 (git-49a47f187e)
    OpenGL ES profile shading language version string: OpenGL ES GLSL ES 3.20`
    ```
## Launch Ubuntu VM

There are three options provided, option 2 and 3 are in progress. Choose the corresponding launch method according to your installation method.

* [Option 1] Launch From `qemu`
* [Option 2] Launch From `virt-manager` (EXPERIMENTAL)
* [Option 3] Launch From `virsh` (EXPERIMENTAL)

### Launch From `qemu`

1. Run `start_ubuntu.sh` to launch ubuntu virtual machine

    ```sh
    cd /home/$USER/sriov/scripts/setup_guest/ubuntu/
    sudo ./start_ubuntu.sh
    ```

### Launch From `virt-manager` (EXPERIMENTAL)

1. Run `virt-manager` to launch ubuntu virtual machine
2. 
    ```sh
    virt-manager
    ```
    <img src=./media/ubuntu_virt.png width="80%">

### Launch From `virsh` (EXPERIMENTAL)

1. Run `virsh` to launch ubuntu  virtual machine

    ```sh
    sudo virsh start ubuntu
    ```

## Advanced Guest VM Launch

   + Customize launch single VM
      The `start_ubuntu.sh` script help in the host
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
                sub-param: show-fps, show fps info in the guest vm primary display.
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

   Run the `start_all_ubuntu.sh`
    ```shell
    #in the host
    cd /home/$USER/scripts/setup_guest/ubuntu/
    sudo ./start_all_ubuntu.sh
    ```
   
    Script enablements:
    1. It has created multiple copies of `OVMF` files.
    2. It has created and setup the Ubuntu guest images. You can check that the images are named as `ubuntu.qcow2`, `ubuntu2.qcow2`, `ubuntu3.qcow2` and `ubuntu4.qcow2`.
    3. Run to start 4 VMs.

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