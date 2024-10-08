# Microsoft Windows 11 VM

## Prerequisites

* Windows 11 ISO. In this example we are using Windows 10 Enterprise version 21H2
* [Windows 10 Cumulative Update](https://catalog.s.download.windowsupdate.com/c/msdownload/update/software/secu/2023/05/windows10.0-kb5026361-x64_961f439d6b20735f067af766e1813936bf76cb94.msu)
* [Intel Graphics Driver](https://cdrdv2.intel.com/v1/dl/getContent/736997/737084?filename=win64.zip) version MR2 101.3111 (win64.zip)
* [SR-IOV Zero Copy Driver](https://www.intel.com/content/www/us/en/download/816539/nex-display-virtualization-drivers-for-alder-lake-s-p-n-and-raptor-lake-s-p-sr-p-core-ps-amston-lake.html?cache=1708585927) version ZC_1447
* [Virtio Driver](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.221-1/virtio-win.iso) version 0.1.221-1

## Installation

1. Run install_windows.sh to start Windows guest installation.

  ```sh
  sudo ./scripts/install_windows.sh
  ```

3. Install Windows Cumulative Update

4. Disable Graphics Driver Updates

5. Install Virtio Driver for Windows
