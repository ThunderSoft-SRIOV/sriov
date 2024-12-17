<!-- TABLE OF CONTENTS -->
# Table of Contents
1. [Disable UEFI Secure Boot](#disable-uefi-secure-boot)
1. [Install Software Packages](#install-software-packages)
1. [Check The Software Package Version](#check-the-software-package-version)
1. [Enable UEFI Secure Boot](#enable-uefi-secure-boot)

# Disable UEFI Secure Boot

1. Make sure you have disabled Secure Boot

    ```sh
    sudo mokutil --sb-state
    ```

    If system returns **SecureBoot enabled** , it means that the system has booted via Secure Boot. And you need to disable Secure Boot by following steps: 
    1) Reboot the system
    2) Enter the BIOS configuration interface
    3) Select *Security* -> *Secure Boot* -> *Disabled*
    4) Save and exit

# Install Software Packages

1. Install kernel packages

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_kernel.sh
    ```

2. Reboot the host

    ```sh
    sudo reboot
    ```

3. Install software after reboot

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_debian.sh
    ```

# Check The Software Package Version

1. Check the kernel version

    ```shell
    uname -r
    ```

    Example output
    ```shell
    6.6.32-debian-sriov
    ```

2. Check the version of all software packages

    ```shell
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_check_version.sh
    ```

    Example output
    ```shell
    gmmlib-sriov                        2410-1
    libdrm-amdgpu1:amd64                2.4.123-1~bpo12+1
    libdrm-common                       2.4.123-1~bpo12+1
    libdrm-dev:amd64                    2.4.123-1~bpo12+1
    libdrm-intel1:amd64                 2.4.123-1~bpo12+1
    libdrm-nouveau2:amd64               2.4.123-1~bpo12+1
    libdrm-radeon1:amd64                2.4.123-1~bpo12+1
    libdrm-sriov                        2410-1
    libdrm2:amd64                       2.4.123-1~bpo12+1
    libva-drm2:amd64                    2.17.0-1
    libva-sriov                         2410-1
    libva-utils-sriov                   2410-1
    libva-x11-2:amd64                   2.17.0-1
    libva2:amd64                        2.17.0-1
    libvariable-magic-perl              0.63-1+b1
    libva-utils-sriov                   2410-1
    media-driver-sriov                  2410-1
    libegl-mesa0:amd64                  24.2.4-1~bpo12+1
    libegl1-mesa:amd64                  22.3.6-1+deb12u1
    libegl1-mesa-dev:amd64              24.2.4-1~bpo12+1
    libgl1-mesa-dri:amd64               24.2.4-1~bpo12+1
    libglapi-mesa:amd64                 24.2.4-1~bpo12+1
    libglu1-mesa:amd64                  9.0.2-1.1
    libglx-mesa0:amd64                  24.2.4-1~bpo12+1
    mesa-common-dev:amd64               24.2.4-1~bpo12+1
    mesa-libgallium:amd64               24.2.4-1~bpo12+1
    mesa-sriov                          2410-1
    mesa-utils                          8.5.0-1
    mesa-utils-bin:amd64                8.5.0-1
    mesa-va-drivers:amd64               24.2.4-1~bpo12+1
    mesa-vdpau-drivers:amd64            24.2.4-1~bpo12+1
    mesa-vulkan-drivers:amd64           24.2.4-1~bpo12+1
    onevpl-gpu-sriov                    2410-1
    onevpl-gpu-sriov                    2410-1
    onevpl-sriov                        2410-1
    libspice-client-glib-2.0-8:amd64    0.42-1
    libspice-client-gtk-3.0-5:amd64     0.42-1
    spice-client                        2410-1
    spice-client-glib-usb-acl-helper    0.42-1
    libspice-protocol-dev               0.14.3-1
    spice-protocol                      2410-1
    libspice-server-dev:amd64           0.15.1-1
    libspice-server1:amd64              0.15.1-1
    spice-server                        2410-1
    intel-igc-core                      1.0.13700.14
    intel-igc-opencl                    1.0.13700.14
    intel-level-zero-gpu                1.3.26032.30
    intel-opencl-icd                    23.13.26032.30
    libigdgmm12:amd64                   22.3.3+ds1-1
    ```

# Enable UEFI Secure Boot

1. Create a custom MOK

    First of all you need to check if you have a key already with the following commands. 

    ```sh
    ls /var/lib/shim-signed/mok/
    ```

    If the key (consisting of the files `MOK.der`, `MOK.pem` and `MOK.priv`) does exist, then you can just use them and no need to create yourself.

    If the key does not exist, you can create your own according to the following steps:

    ```sh
    sudo mkdir -p /var/lib/shim-signed/mok/

    cd /var/lib/shim-signed/mok/

    # Replace "/CN=My Name/" to your own information, eg. "/CN=ThunderSoft/"
    sudo openssl req -nodes -new -x509 -newkey rsa:2048 -keyout MOK.priv -outform DER -out MOK.der -days 3650 -subj "/CN=My Name/"

    sudo openssl x509 -inform der -in MOK.der -out MOK.pem
    ```

2. Enroll the key

    ```sh
    sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
    ```

    *Note: You will be prompted here to enter a one-time password, please remember the password*

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
    ```
    /var/lib/shim-signed/mok/MOK.der is already enrolled
    ```

3. Sign kernel with the MOK key

    *Note: First, install [sbsigntool](https://packages.debian.org/search?keywords=sbsigntool)*

    ```sh
    cd /var/lib/shim-signed/mok/
    sudo sbsign --key MOK.priv --cert MOK.pem "/boot/vmlinuz-6.6.32-debian-sriov" --output "/boot/vmlinuz-6.6.32-debian-sriov.tmp"
    sudo mv "/boot/vmlinuz-6.6.32-debian-sriov.tmp" "/boot/vmlinuz-6.6.32-debian-sriov"
    ```

4. Check the secure boot state

    ```sh
    sudo mokutil --sb-state
    ```

    If system returns **SecureBoot disabled**, you need to enable Secure Boot by following steps: 
    1) Reboot the system
    2) Enter the BIOS configuration interface
    3) Select *Security* -> *Secure Boot* -> *Enabled*
    4) Save and exit
