# Table of Contents
1. [Preparation](#preparation)
2. [Build Packages](#build-packages)

<!-- PREPARATION -->
# Preparation

1. Download source list file

    ```shell
    sudo echo 'deb http://deb.debian.org/debian bookworm-backports main non-free-firmware' | sudo tee -a /etc/apt/sources.list.d/debian_sriov.list
    sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D' /etc/apt/sources.list.d/debian_sriov.list
    sudo -E curl -SsL -o /etc/apt/sources.list.d/thundersoft-sriov.list https://ThunderSoft-SRIOV.github.io/debian.ppa/debian/doc/thundersoft-sriov.list
    ```

2. Download the GPG key

    ```shell
    sudo -E curl -SsL -o /etc/apt/trusted.gpg.d/thundersoft-sriov.asc https://ThunderSoft-SRIOV.github.io/debian.ppa/debian/doc/KEY.gpg
    ```

3. Set the preferred list

    ```shell
    sudo -E curl -SsL -o /etc/apt/preferences.d/thundersoft-sriov-preferred https://ThunderSoft-SRIOV.github.io/debian.ppa/debian/doc/thundersoft-sriov-preferred
    ```

4. Get the latest apt from Debian* archive

    ```shell
    sudo apt update
    ```

# Build Packages

1. Get source code from ppa

    ```shell
    # Please replace <package name> with your target package name
    sudo apt-get source <package name>
    ```

2. Install dependency packages

    ```shell
    # Please replace <package name> with your target package name
    sudo apt-get build-dep <package name>
    ```

3. Build packages

    ```shell
    # Go to the source directory and execute the compile command. After successful execution, .deb packages will be generated in the previous directory
    sudo dpkg-buildpackage -us -uc
    ```