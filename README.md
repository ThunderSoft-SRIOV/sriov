<!-- ABOUT THE PROJECT -->
## About The Project

Graphics SR-IOV is Intel's latest Virtualization Technology for Graphics. 

<!-- GETTING STARTED -->
## Getting Started

### Installation
  * Quick Install
  * [Manual Install](https://github.com/ThunderSoft-SRIOV/ppa/blob/main/README.md)

### Quick Install

   ```sh
   ./scripts/install_sriov.sh
   ```

### Enable UEFI Secure Boot

  * [Enable Secure Boot](docs/secure-boot.md)

### Update grub file

1. Specify kernel version to boot.
    ```sh
    GRUB_DEFAULT="Advanced options for Debian GNU/Linux>Debian GNU/Linux, with Linux 6.6.32-debian-sriov"
    ```

2. Add kernel option.
    ```sh
    GRUB_CMDLINE_LINUX_DEFAULT="quiet console=tty0,115200n8 intel_iommu=on iommu=soft vt_handoff=7"
    GRUB_CMDLINE_LINUX="splash i915.enable_guc=3 i915.max_vfs=7 i915.force_probe=* udmabuf.list_limit=8192"
    ```

3. Update grub.
    ```sh
    sudo update-grub

    sudo reboot
    ```

4. After reboot, check the kernel version.
    ```sh
    uname -r
    ```
    Output:
    ```sh
    6.6.32-debian-sriov
    ```

<!-- USAGE EXAMPLES -->
### Usage
1. Setup and deploy Windows VM.
  * [Deploy Windows VM](docs/deploy-windows-vm.md)

2. Setup and deploy Linux VM.
  * [Deploy Windows VM](docs/deploy-ubuntu-vm.md)
