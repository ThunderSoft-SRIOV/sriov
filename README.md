<!-- ABOUT THE PROJECT -->
## About The Project

Graphics SR-IOV is Intel's latest Virtualization Technology for Graphics. 

<!-- GETTING STARTED -->
## Getting Started

### Installation
  * Source Install
  * Package Install

### Source Install

Install and setup from source code.

1. Setup kernel

  ```sh
  sudo ./scripts/sriov_setup_kernel.sh
  ```

2. Setup debian

  ```sh
  sudo ./scripts/sriov_setup_debian.sh
  ```

### Source Install

Install and setup from ppa.

1. Setup kernel

  ```sh
  sudo ./scripts/sriov_setup_kernel.sh --use-install-files
  ```

2. Setup debian

  ```sh
  sudo ./scripts/sriov_setup_debian.sh --use-install-files
  ```

<!-- USAGE EXAMPLES -->
### Usage

Follow the links below for instructions on how to setup and deploy virtual machines using this toolkit

[Deploy Windows Virtual Machine](docs/deploy-windows-vm.md)

[Deploy Linux Virtual Machine](docs/deploy-ubuntu-vm.md)
