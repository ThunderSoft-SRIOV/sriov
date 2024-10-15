# Guest Ubuntu Virtual Machine

## Prerequisites
### Guest Operating System Requirements

* Ubuntu 22.04 ISO, Download and install the Intel IOT Ubuntu 22.04 LTS from the official Ubuntu website.
https://cdimage.ubuntu.com/releases/jammy/release/inteliot/ubuntu-22.04-desktop-amd64+intel-iot.iso

## Create Ubuntu VM Image
* Execute the following command on the host
  ```
  # sudo apt install -t bookworm-backports ovmf
  
  Run install_ubuntu.sh to start Ubuntu guest installation.
  
  sudo ./scripts/install_ubuntu.sh
  ```

* Then press enter and continue boot to Ubuntu as shown in the screen below.

  <img src=./media/ubuntusetup1.png width="80%">

* Run Ubuntu OS installation to install into the guest image and reboot after completion.
* Open a terminal within the guest VM.
* Run the command shown below to upgrade Ubuntu software to the latest in the guest VM.
  ```
  # Upgrade Ubuntu software
  sudo apt -y update
  sudo apt -y upgrade
  sudo apt -y install openssh-server
  ```

* Copy the following files and directories from the /home/$USER directory of the hostto the /home/$USER/ directory of the guest.
  ```
  scp -r -P 2222 $path/scripts/ $path/sriov_patches/ $path/sriov_patches/ $user@localhost:/home/$user/Documents/
  ```
* Run sriov_setup_kernel.sh in Ubuntu guest VM.
  ```
  # This will install kernel and firmware, and update grub
  
  sudo ./sriov_setup_kernel.sh
  ```
*  Reboot the system.
  ```
  sudo reboot
  ```
* After rebooting, check that the kernel is the installed version.
  ```
  uname -r
  6.6.32
  ```
*  Prepare and generate the install files.
  ```
  cp $path/sriov_patches/  ./
  sudo ./sriov_prepare_projects.sh
  sudo ./sriov_install_projects.sh
  
  After executing the above command, 2 folders will be generated
  ./packages
  ./sriov_install
  ```
* Run configure_ubuntu_guest.sh in Ubuntu guest VM.
  ```
  # This will install userspace libraries and tools
  cp -r packages ./
  cp -r sriov_install ./
  sudo ./configure_ubuntu_guest.sh
  
  ```
* After the installation has completed, reboot the guest when prompted.
* Next, shutdown the guest properly. The Ubuntu image ubuntu.qcow2 is now 
ready to use.

## After restarting, check the installation program

* The following are the corresponding versions after installing the program
  
  |   Application Name   |    Version     |
  | :------------------: | :------------: |
  |        kernel        |     6.6.32     |
  |     firmware-guc     |      7.13      |
  |     firmware-huc     |      7.9       |
  |        gmmlib        |     22.3.5     |
  |        libdrm        |    2.4.114     |
  |        libva         |     2.18.0     |
  |     libva-utils      |     2.18.0     |
  |     media-driver     |     23.1.0     |
  |         mesa         |     23.2.1     |
  |      onevpl-gpu      |     22.6.5     |
  |        onevpl        |     22.6.5     |
  |     spice-client     |     v0.42      |
  |    spice-protocol    |    v0.14.4     |
  |     spice-server     |    v0.15.2     |
  |    intel-igc-core    |  1.0.13700.14  |
  |   intel-igc-opencl   |  1.0.13700.14  |
  | intel-level-zero-gpu |  1.3.26032.30  |
  |   intel-opencl-icd   | 23.13.26032.30 |
  |     libigdgmm12      |      22.3      |
  
* Check Ubuntu configuration
  ```
  sudo cat /etc/default/grub
  
  For example output:
  
  GRUB_DEFAULT="Advanced options for Debian GNU/Linux>Debian GNU/Linux, with Linux 6.6.32-ubuntu"
  .....
  GRUB_CMDLINE_LINUX_DEFAULT="quiet console=tty0,115200n8 intel_iommu=on iommu=soft vt_handoff=7"
  GRUB_CMDLINE_LINUX="splash i915.enable_guc=3 i915.force_probe=* udmabuf.list_limit=8192"
  
  ```
* Check the loading driver
  ```
  glxinfo -B
  
  For example output:
  
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
  OpenGL ES profile shading language version string: OpenGL ES GLSL ES 3.20
  ```