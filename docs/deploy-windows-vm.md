<a name="win10-vm-top"></a>

# Microsoft Windows 11 VM

## Prerequisites

* Windows 11 ISO. In this example we are using Windows 10 Enterprise version 21H2
* [Windows 11 Cumulative Update](https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/e3472ba5-22b6-46d5-8de2-db78395b3209/public/windows11.0-kb5031455-x64_d1c3bafaa9abd8c65f0354e2ea89f35470b10b65.msu)
* [Intel Graphics Driver](https://cdrdv2.intel.com/v1/dl/getContent/736997/737084?filename=win64.zip) version MR2 101.3111 (win64.zip)
* [SR-IOV Zero Copy Driver](https://www.intel.com/content/www/us/en/download/816539/nex-display-virtualization-drivers-for-alder-lake-s-p-n-and-raptor-lake-s-p-sr-p-core-ps-amston-lake.html?cache=1708585927) version ZC_1447
* [Virtio Driver](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.221-1/virtio-win.iso) version 0.1.221-1

## Installation

### Create Windows VM Image

1. Run install_windows.sh to start Windows guest installation.

  ```sh
  sudo ./scripts/install_windows.sh
  ```

2. Follow Windows installation steps until Windows installation is successful. And shutdown the Windows guest.

  <img src=./media/winsetup1.png width="80%">
  <img src=./media/winsetup2.png width="80%">

3. From Debian GUI, launch Windows guest VM with start_windows.sh.

  ```sh
  sudo ./scripts/start_windows.sh
  ```

4. Copy Intel Graphics Driver and Windows 11 update files to Windows desktop. Launch Windows 11 update installer and make sure Windows version is updated.

6. Unzip SR-IOV Zero Copy Driver installer, search for 'Windows PowerShell' and run it as an administrator. Make sure SR-IOV Zero Copy Driver is successfully installed

  ```sh
  C:\> Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope CurrentUser
  C:\> .\DVInstaller.ps1
  ```

  <img src=./media/zerocopydrv.png width="80%">

5. Unzip Intel Graphics Driver installer and navigate into the install folder and double click on installer.exe to launch the 
installer. Make sure Intel Graphics Driver is successfully installed.

  <img src=./media/gfxdrvinstall.png width="80%">
  <img src=./media/gfxdrv.png width="80%">

<p align="right">(<a href="#win10-vm-top">back to top</a>)</p>
