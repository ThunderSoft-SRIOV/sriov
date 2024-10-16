<a name="win11-vm-top"></a>

# Microsoft Windows 11 VM

## Prerequisites

* Windows 11 ISO.
* [Windows 11 Cumulative Update](https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/e3472ba5-22b6-46d5-8de2-db78395b3209/public/windows11.0-kb5031455-x64_d1c3bafaa9abd8c65f0354e2ea89f35470b10b65.msu)
* [Intel Graphics Driver](https://cdrdv2.intel.com/v1/dl/getContent/736997/737084?filename=win64.zip) version MR2 101.3111
* [SR-IOV Zero Copy Driver](https://www.intel.com/content/www/us/en/download/816539/nex-display-virtualization-drivers-for-alder-lake-s-p-n-and-raptor-lake-s-p-sr-p-core-ps-amston-lake.html?cache=1708585927) version ZC_1447
* [Virtio Driver](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.221-1/virtio-win.iso) version 0.1.221-1

## Create Windows VM Image

  * Create Windows VM Image Using `qemu`
  * Create Windows VM Image Using `virt-manager`
  * Create Windows VM Image Using `virsh`

*Note: Please choose one of the installation methods*

### Create Windows VM Image Using `qemu`

1. Run `install_windows.sh` to start Windows guest installation.

  ```sh
  sudo ./scripts/setup_guest/win11/install_windows.sh
  ```

2. Follow Windows installation steps until installation is successful.

  <img src=./media/winsetup1.png width="80%">
  <img src=./media/winsetup2.png width="80%">

3. Launch Windows guest VM with `start_windows.sh`.

  ```sh
  sudo ./scripts/setup_guest/win11/start_windows.sh
  ```

4. [Optional] Launch Multiple Windows Guest VMs. In this example we started 4 vms.

  ```sh
  sudo ./scripts/setup_guest/win11/start_multiple_windows.sh
  ```

### Create Windows VM Image Using `virt-manager`

1. Run `virt-manager` to start Windows guest installation.

  ```sh
  virt-manager
  ```

2. Select image and follow Windows installation steps until installation is successful.

  <img src=./media/virtsetup1.png width="80%">
  <img src=./media/virtsetup2.png width="80%">
  <img src=./media/virtsetup3.png width="80%">
  <img src=./media/virtsetup4.png width="80%">
  <img src=./media/virtsetup5.png width="80%">

3. Launch windows after successful installation.

  <img src=./media/virtstart1.png width="80%">

4. [Optional] Launch Multiple Windows Guest VMs. Please refer to the step 2

### Create Windows VM Image Using `virsh`

1. Run `virsh_install_windows.sh` to start Windows guest installation.

  ```sh
  sudo ./scripts/setup_guest/win11/virsh_install_windows.sh
  ```

2. Follow Windows installation steps until installation is successful.

  ```sh
  sudo virsh list --all
  ```

  output:
  ```sh
  Id   Name    State
  ------------------------
  -    win11   shut off
  ```

3. Launch windows after successful installation.

  ```sh
  sudo virsh start win11
  ```

## Install Drivers and Windows 11 update

1. Copy Intel Graphics Driver and Windows 11 update files to Windows desktop. Launch Windows 11 update installer and make sure Windows version is updated.

2. Unzip SR-IOV Zero Copy Driver installer, search for 'Windows PowerShell' and run it as an administrator. Make sure SR-IOV Zero Copy Driver is successfully installed

  ```sh
  C:\> Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope CurrentUser
  C:\> .\DVInstaller.ps1
  ```

  <img src=./media/zerocopydrv.png width="80%">

3. Unzip Intel Graphics Driver installer and navigate into the install folder and double click on installer.exe to launch the 
installer. Make sure Intel Graphics Driver is successfully installed.

  <img src=./media/gfxdrvinstall.png width="80%">
  <img src=./media/gfxdrv.png width="80%">

<p align="right">(<a href="#win11-vm-top">back to top</a>)</p>
