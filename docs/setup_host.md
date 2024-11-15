<!-- TABLE OF CONTENTS -->
# Table of Contents
1. [Install Software Packages](#install-software-packages)
1. [Enable UEFI Secure Boot](#enable-uefi-secure-boot)

# Install Software Packages

1. Make sure you have disabled Secure Boot

    ```sh
    sudo mokutil --sb-state
    ```

    If system returns **SecureBoot enabled** , it means that the system has booted via Secure Boot. And you need to disable Secure Boot by following steps: 
    1) Reboot the system
    2) Enter the BIOS configuration interface
    3) Select *Security* -> *Secure Boot* -> *Disabled*
    4) Save and exit

2. Install kernel packages

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_kernel.sh
    ```

3. Reboot the host

    ```sh
    sudo reboot
    ```

4. Install software after reboot

    ```sh
    cd /home/$USER/sriov
    sudo ./scripts/setup_host/sriov_setup_debian.sh
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
