<!-- TABLE OF CONTENTS -->
# Table of Contents
1. [Install Software Packages](#install-software-packages)
1. [Enable UEFI Secure Boot](#enable-uefi-secure-boot)

# Install Software Packages

1. Install kernel packages

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_kernel.sh --use-ppa-files
    ```

2. Reboot the host

    ```sh
    sudo reboot
    ```

3. Install software after reboot

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_debian.sh --use-ppa-files
    ```

# Enable UEFI Secure Boot

1. Download `MOK.der` from ppa

    ```sh
    cd /home/$USER/sriov
    sudo curl -SsL -o MOK.der https://ThunderSoft-SRIOV.github.io/ppa/debian/MOK.der
    ```

2. Enroll the key

    ```sh
    cd /home/$USER/sriov
    sudo mokutil --import MOK.der
    ```

    At next reboot, the device firmware should launch its MOK manager and prompt the user to review the new key and confirm its enrollment using the one-time password. Any kernel modules (or kernels) that have been signed with this MOK should now be loadable.

    To verify the MOK was loaded correctly:

    ```sh
    cd /home/$USER/sriov
    sudo mokutil --test-key MOK.der
    ```

    output
    ```
    /var/lib/shim-signed/mok/MOK.der is already enrolled
    ```

3. Check the secure boot state

    ```sh
    sudo mokutil --sb-state
    ```

    If system returns **SecureBoot enabled** , it means that the system has booted via Secure Boot. Otherwise, you need to enable Secure Boot by following steps: 
    1) Reboot the system
    2) Enter the BIOS configuration interface
    3) Select *Security* -> *Secure Boot* -> *Enabled*
    4) Save and exit
