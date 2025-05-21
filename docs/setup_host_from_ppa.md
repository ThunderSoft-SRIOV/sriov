<!-- TABLE OF CONTENTS -->
# Table of Contents

1. [Register ThunderSoft Machine Owner Key for Secure Boot](#register-thundersoft-machine-owner-key-for-secure-boot)
2. [Install Software Packages](#install-software-packages)
3. [Check The Software Package Version](#check-the-software-package-version)

## Register ThunderSoft Machine Owner Key for Secure Boot

1. Check the secure boot state

    ```sh
    sudo mokutil --sb-state
    ```

    *Note: You might need to create user pasword  to enable secure boot. Please refer to your system manual for details*

    If system returns **SecureBoot disabled**, you need to enable Secure Boot by following steps:
      1) Reboot the system
      2) Enter the BIOS configuration interface
      3) Select *Security* -> *Secure Boot* -> *Enabled*
      4) Save and exit

2. Download `MOK.der` from ppa

    ```sh
    sudo mkdir -p /var/lib/shim-signed/mok/
    cd /var/lib/shim-signed/mok/
    sudo -E curl -SsL -o MOK.der https://ThunderSoft-SRIOV.github.io/ppa/debian/doc/MOK.der
    ```

3. Enroll the key

    ```sh
    sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
    ```

    *Note: You will be prompted here to enter a one-time password, please remember the password*

4. Reboot the host

    ```sh
    sudo reboot
    ```

    At next reboot, the device firmware should launch it's MOK manager and prompt the user to review the new key and confirm it's enrollment, using the one-time password. Any kernel modules (or kernels) that have been signed with this MOK should now be loadable.

    <img src=./media/secureboot1.png width="80%">
    <img src=./media/secureboot2.png width="80%">
    <img src=./media/secureboot3.png width="80%">
    <img src=./media/secureboot4.png width="80%">
    <img src=./media/secureboot5.png width="80%">
    <img src=./media/secureboot6.png width="80%">

    To verify the MOK was loaded correctly after reboot:

    ```sh
    sudo mokutil --test-key /var/lib/shim-signed/mok/MOK.der
    ```

    output

    ```sh
    /var/lib/shim-signed/mok/MOK.der is already enrolled
    ```

5. Check the secure boot state

    ```sh
    sudo mokutil --sb-state
    ```

# Install Software Packages

1. Install software packages

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_install_host.sh
    ```

2. Reboot the host

    ```sh
    sudo reboot
    ```

3. Setup host after reboot

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_host.sh
    ```

# Check The Software Package Version

1. Check the kernel version

    ```shell
    uname -r
    ```

    Example output
    ```shell
    6.6-intel
    ```

2. Check the version of all software packages

    ```shell
    cd /home/$USER/sriov
    ./scripts/setup_host/sriov_check_version.sh
    ```

    Example output
    ```shell
    libdrm-amdgpu1:amd64                2.4.120-1ppa1~sriov~bookworm1
    libdrm-common                       2.4.120-1ppa1~sriov~bookworm1
    libdrm-dev:amd64                    2.4.120-1ppa1~sriov~bookworm1
    libdrm-intel1:amd64                 2.4.120-1ppa1~sriov~bookworm1
    libdrm-nouveau2:amd64               2.4.120-1ppa1~sriov~bookworm1
    libdrm-radeon1:amd64                2.4.120-1ppa1~sriov~bookworm1
    libdrm-tests                        2.4.120-1ppa1~sriov~bookworm1
    libdrm2:amd64                       2.4.120-1ppa1~sriov~bookworm1
    libva2:amd64                        2.22.0-1ppa1~sriov~bookworm1
    libva-dev:amd64                     2.22.0-1ppa1~sriov~bookworm1
    libva-drm2:amd64                    2.22.0-1ppa1~sriov~bookworm1
    libva-glx2:amd64                    2.22.0-1ppa1~sriov~bookworm1
    libva-wayland2:amd64                2.22.0-1ppa1~sriov~bookworm1
    libva-x11-2:amd64                   2.22.0-1ppa1~sriov~bookworm1
    va-driver-all:amd64                 2.22.0-1ppa1~sriov~bookworm1
    intel-gmmlib:amd64                  22.5.1-1ppa1~sriov~bookworm1
    libigdgmm-dev:amd64                 22.5.1-1ppa1~sriov~bookworm1
    libigdgmm12:amd64                   22.5.1-1ppa1~sriov~bookworm1
    libvpl2                             1:2.12.0-1ppa1~sriov~bookworm1
    libvpl-dev                          1:2.12.0-1ppa1~sriov~bookworm1
    libmfx-gen1.2                       24.3.2-1ppa1~sriov~bookworm1
    libmfx-gen-dev                      24.3.2-1ppa1~sriov~bookworm1
    intel-media-va-driver:amd64         24.3.2-1ppa1~sriov~bookworm1
    libigfxcmrt-dev:amd64               24.3.2-1ppa1~sriov~bookworm1
    libigfxcmrt7:amd64                  24.3.2-1ppa1~sriov~bookworm1
    libspice-client-glib-2.0-8:amd64    0.42-1ppa1~sriov~bookworm1
    libspice-client-gtk-3.0-5:amd64     0.42-1ppa1~sriov~bookworm1
    libspice-client-gtk-3.0-5:amd64     0.42-1ppa1~sriov~bookworm1
    spice-client-gtk                    0.42-1ppa1~sriov~bookworm1
    spice-client-glib-usb-acl-helper    0.42-1ppa1~sriov~bookworm1
    qemu-system-modules-opengl          1:8.2.4-ppa1~sriov~bookworm1
    qemu-guest-agent                    1:8.2.4-ppa1~sriov~bookworm1
    qemu-system                         1:8.2.4-ppa1~sriov~bookworm1
    qemu-system-arm                     1:8.2.4-ppa1~sriov~bookworm1
    qemu-system-common                  1:8.2.4-ppa1~sriov~bookworm1
    qemu-system-data                    1:8.2.4-ppa1~sriov~bookworm1
    qemu-system-gui                     1:8.2.4-ppa1~sriov~bookworm1
    qemu-system-mips                    1:8.2.4-ppa1~sriov~bookworm1
    qemu-system-misc                    1:8.2.4-ppa1~sriov~bookworm1
    qemu-system-modules-spice           1:8.2.4-ppa1~sriov~bookworm1
    qemu-system-ppc                     1:8.2.4-ppa1~sriov~bookworm1
    qemu-system-sparc                   1:8.2.4-ppa1~sriov~bookworm1
    qemu-system-x86                     1:8.2.4-ppa1~sriov~bookworm1
    qemu-user                           1:8.2.4-ppa1~sriov~bookworm1
    qemu-user-binfmt                    1:8.2.4-ppa1~sriov~bookworm1
    qemu-user-binfmt                    1:8.2.4-ppa1~sriov~bookworm1
    qemu-block-extra                    1:8.2.4-ppa1~sriov~bookworm1
    qemu-utils                          1:8.2.4-ppa1~sriov~bookworm1
    libd3dadapter9-mesa:amd64           24.0.5-1ppa1~sriov~bookworm1
    libd3dadapter9-mesa-dev:amd64       24.0.5-1ppa1~sriov~bookworm1
    libd3dadapter9-mesa-dev:amd64       24.0.5-1ppa1~sriov~bookworm1
    libegl-mesa0:amd64                  24.0.5-1ppa1~sriov~bookworm1
    libegl1-mesa-dev:amd64              24.0.5-1ppa1~sriov~bookworm1
    libgl1-mesa-dev:amd64               24.0.5-1ppa1~sriov~bookworm1
    libgl1-mesa-dri:amd64               24.0.5-1ppa1~sriov~bookworm1
    libglapi-mesa:amd64                 24.0.5-1ppa1~sriov~bookworm1
    libgles2-mesa-dev:amd64             24.0.5-1ppa1~sriov~bookworm1
    libglx-mesa0:amd64                  24.0.5-1ppa1~sriov~bookworm1
    libosmesa6:amd64                    24.0.5-1ppa1~sriov~bookworm1
    libosmesa6-dev:amd64                24.0.5-1ppa1~sriov~bookworm1
    libosmesa6-dev:amd64                24.0.5-1ppa1~sriov~bookworm1
    mesa-common-dev:amd64               24.0.5-1ppa1~sriov~bookworm1
    mesa-drm-shim:amd64                 24.0.5-1ppa1~sriov~bookworm1
    mesa-opencl-icd:amd64               24.0.5-1ppa1~sriov~bookworm1
    mesa-va-drivers:amd64               24.0.5-1ppa1~sriov~bookworm1
    mesa-vdpau-drivers:amd64            24.0.5-1ppa1~sriov~bookworm1
    mesa-vulkan-drivers:amd64           24.0.5-1ppa1~sriov~bookworm1
    ```
