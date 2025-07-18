#!/bin/bash

# Copyright (c) 2023-2025 Intel Corporation.
# All rights reserved.
set -x
set -Eeuo pipefail

#---------      Global variable     -------------------
# PPA url for Intel overlay installation
# Add each required entry on new line
PPA_URLS_22=(
    "https://download.01.org/intel-linux-overlay/ubuntu jammy main non-free multimedia kernels"
)
PPA_URLS_24=(
    "https://download.01.org/intel-linux-overlay/ubuntu noble main non-free multimedia kernels"
)
# corresponding GPG key to use for each PPA_URL entry above in same sequence.
# If GPG key is not set correctly,
# Set to either one of below options:
#   To auto use GPG key found in PPA entry (check PPA repository has required key available), set to: "auto"
#   To force download GPG key at stated url, set to: "url of gpg key file"
#   To force trusted access without GPG key (for unsigned PPA only), set to: "force"
PPA_GPGS=(
    "auto"
)
# Set corresponding to use proxy as set in host env variable or not for each PPA_URL entry above in same sequence.
# Set to either one of below options:
#   To use auto proxy, set to: ""
#   To not use proxy, set to: "--no-proxy"
PPA_WGET_NO_PROXY=(
    ""
)
# Set additional apt proxy configuration required to access PPA_URL entries set.
# Set to either one of below options:
#   For no proxy required for PPA access, set to: ""
#   For proxy required (eg. using myproxyserver.com at mynetworkdomain.com), set to:
#     'Acquire::https::proxy::myproxyserver.com "DIRECT";' 'Acquire::https::proxy::*.mynetworkdomain.com "DIRECT";'
#     where
#     Change myproxyserver.com to your proxy server
#     Change mynetworkdomain.com to your network domain
PPA_APT_CONF=(
    ""
)
# PPA APT repository pin and priority
# Reference: https://wiki.debian.org/AptConfiguration#Always_prefer_packages_from_a_repository
PPA_PIN_22="release o=intel-iot-linux-overlay"
PPA_PIN_24="release o=intel-iot-linux-overlay-noble"
PPA_PIN_PRIORITY=2000

# Add entry for each additional package to install into guest VM
PACKAGES_ADD_INSTALL=(
    ""
)

NO_BSP_INSTALL=0
KERN_PATH=""
KERN_INSTALL_FROM_PPA=0
KERN_PPA_VER=""
LINUX_FW_PPA_VER=""
RT=0
DRM_DRV_SUPPORTED=('i915')
DRM_DRV_SELECTED=""
FORCE_SW_CURSOR=0

script=$(realpath "${BASH_SOURCE[0]}")
#scriptpath=$(dirname "$script")
LOGTAG=$(basename "$script")
LOGD="logger -t $LOGTAG"
LOGE="logger -s -t $LOGTAG"

os_version=`lsb_release -rs`
if [[ "$os_version" =~ "24" ]]; then
	PPA_URLS=$PPA_URLS_24
	PPA_PIN=$PPA_PIN_24
elif [[ "$os_version" =~ "22" ]]; then
	PPA_URLS=$PPA_URLS_22
	PPA_PIN=$PPA_PIN_22
fi

#---------      Functions    -------------------
declare -F "check_non_symlink" >/dev/null || function check_non_symlink() {
    if [[ $# -eq 1 ]]; then
        if [[ -L "$1" ]]; then
            $LOGE "Error: $1 is a symlink."
            exit 255
        fi
    else
        $LOGE "Error: Invalid param to ${FUNCNAME[0]}"
        exit 255
    fi
}

declare -F "check_file_valid_nonzero" >/dev/null || function check_file_valid_nonzero() {
    if [[ $# -eq 1 ]]; then
        check_non_symlink "$1"
        fpath=$(realpath "$1")
        if [[ $? -ne 0 || ! -f $fpath || ! -s $fpath ]]; then
            $LOGE "Error: $fpath invalid/zero sized"
            exit 255
        fi
    else
        $LOGE "Error: Invalid param to ${FUNCNAME[0]}"
        exit 255
    fi
}

declare -F "check_dir_valid" >/dev/null || function check_dir_valid() {
    if [[ $# -eq 1 ]]; then
        check_non_symlink "$1"
        dpath=$(realpath "$1")
        if [[ $? -ne 0 || ! -d $dpath ]]; then
            $LOGE "Error: $dpath invalid directory" | tee -a "$LOG_FILE"
            exit 255
        fi
    else
        $LOGE "Error: Invalid param to ${FUNCNAME[0]}"
        exit 255
    fi
}

function check_url() {
    local url=$1

    if ! wget --timeout=10 --tries=1 "$url" -nv --spider; then
		# try again without proxy
        echo "Error: Network issue, unable to access $url"
        echo "Error: Please check the internet access connection"
        echo "Solution to Network Problems One: Add a Proxy"
        echo "Proxy address depends on user environment. Usually by “export http_proxy=http://proxy_ip_url:proxy_port”"
        echo "Proxy address depends on user environment. Usually by “export https_proxy=https://proxy_ip_url:proxy_port”"
        echo "For example:"
        echo "export http_proxy=http://proxy-domain.com:912"
        echo "export https_proxy=http://proxy-domain.com:912"
        exit 255
    fi
}

function set_drm_drv() {
    $LOGD "${FUNCNAME[0]} begin"
    local drm_drv=""

    if [[ -z "${1+x}" || -z "$1" ]]; then
        $LOGE "${BASH_SOURCE[0]}: invalid drm_drv param"
        return 255
    fi
    for idx in "${!DRM_DRV_SUPPORTED[@]}"; do
        if [[ "$1" == "${DRM_DRV_SUPPORTED[$idx]}" ]]; then
            drm_drv="${DRM_DRV_SUPPORTED[$idx]}"
            break
        fi
    done
    DRM_DRV_SELECTED="$drm_drv"
    if [[ -z "${drm_drv+x}" || -z "$drm_drv" ]]; then
        $LOGE "ERROR: unsupported intel integrated GPU driver option $drm_drv."
        return 255
    fi

    $LOGD "${FUNCNAME[0]} end"
}

function install_kernel_from_deb() {
    $LOGD "${FUNCNAME[0]} begin"
    if [[ -z "${1+x}" || -z $1 ]]; then
        $LOGE "Error: empty path to kernel debs"
        return 255
    fi
    local path
    path=$(realpath "$1")
    if [ ! -d "$path" ]; then
        $LOGE "Error: invalid path to linux-header and linux-image debs given.($path)"
        return 255
    fi
    check_dir_valid "$1"
    if [[ ! -f "$path"/linux-headers.deb || ! -f "$path"/linux-image.deb ]]; then
        $LOGE "Error: linux-headers.deb or linux-image.deb missing from ($path)"
        return 255
    fi
    check_file_valid_nonzero "$path"/linux-headers.deb
    check_file_valid_nonzero "$path"/linux-image.deb
    # Install Intel kernel overlay
    sudo dpkg -i "$path"/linux-headers.deb "$path"/linux-image.deb

    # Update boot menu to boot to the new kernel
    kernel_version=$(dpkg --info "$path"/linux-headers.deb | grep "Package: " | awk -F 'linux-headers-' '{print $2}')
    sudo sed -i -r -e "s/GRUB_DEFAULT=.*/GRUB_DEFAULT='Advanced options for Ubuntu>Ubuntu, with Linux $kernel_version'/" /etc/default/grub
    sudo update-grub

    $LOGD "${FUNCNAME[0]} end"
}

function install_kernel_from_ppa() {
    $LOGD "${FUNCNAME[0]} begin"
    if [ -z "$1" ]; then
        $LOGE "Error: empty kernel ppa version"
        return 255
    fi

    # Install Intel kernel overlay
    echo "kernel PPA version: $1"
    sudo apt install -y --allow-downgrades linux-headers-"$1" linux-image-"$1" || return 255

    # Update boot menu to boot to the new kernel
    local kernel_name
    kernel_name=$(echo "$1" | awk -F '=' '{print $1}')
    sudo sed -i -r -e "s/GRUB_DEFAULT=.*/GRUB_DEFAULT='Advanced options for Ubuntu>Ubuntu, with Linux $kernel_name'/" /etc/default/grub
    sudo update-grub

    $LOGD "${FUNCNAME[0]} end"
}

function setup_overlay_ppa() {
    $LOGD "${FUNCNAME[0]} begin"

    # Install Intel BSP PPA and required GPG keys
    cat /dev/null > /etc/apt/sources.list.d/ubuntu_bsp.list
    for i in "${!PPA_URLS[@]}"; do
        url=$(echo "${PPA_URLS[$i]}" | awk -F' ' '{print $1}')
        check_url "$url" || return 255
        if [[ "${PPA_GPGS[$i]}" != "force" ]]; then
            echo deb "${PPA_URLS[$i]}" | sudo tee -a /etc/apt/sources.list.d/ubuntu_bsp.list
            echo deb-src "${PPA_URLS[$i]}" | sudo tee -a /etc/apt/sources.list.d/ubuntu_bsp.list

            if [[ "${PPA_GPGS[$i]}" == "auto" ]]; then
                ppa_gpg_key=$(wget "${PPA_WGET_NO_PROXY[$i]}" -q -O - --timeout=10 --tries=1 "$url" | awk -F'.gpg">|&' '{ print $2 }' | awk -F '.gpg|&' '{ print $1 }' | xargs )
                if [[ -z "$ppa_gpg_key" ]]; then
                    $LOGE "Error: unable to auto get GPG key for PPG url ${PPA_URLS[$i]}"
                    return 255
                fi
                sudo -E wget "$url/$ppa_gpg_key.gpg" -O /etc/apt/trusted.gpg.d/"$ppa_gpg_key".gpg
            else
                if [[ -n "${PPA_GPGS[$i]}" ]]; then
                    gpg_key_name=$(basename "${PPA_GPGS[$i]}")
                    if [[ ! -f /etc/apt/trusted.gpg.d/$gpg_key_name ]]; then
                        sudo -E wget "${PPA_GPGS[$i]}" -O /etc/apt/trusted.gpg.d/"$gpg_key_name"
                    fi
                fi
            fi
        else
            echo "deb [trusted=yes] ${PPA_URLS[$i]}" | sudo tee -a /etc/apt/sources.list.d/ubuntu_bsp.list
        fi
    done

    # Pin Intel BSP PPA
    echo -e "Package: *\nPin: $PPA_PIN\nPin-Priority: $PPA_PIN_PRIORITY" | sudo tee -a /etc/apt/preferences.d/priorities

    # Add PPA apt proxy settings if any
    if [[ -n "${ftp_proxy+x}" && -n "$ftp_proxy" ]]; then
        echo "Acquire::ftp::Proxy \"$ftp_proxy\";" | sudo tee -a /etc/apt/apt.conf.d/99proxy.conf
    fi
    if [[ -n "${http_proxy+x}" && -n "$http_proxy" ]]; then
        echo "Acquire::http::Proxy \"$http_proxy\";" | sudo tee -a /etc/apt/apt.conf.d/99proxy.conf
    fi
    if [[ -n "${https_proxy+x}" && -n "$https_proxy" ]]; then
        echo "Acquire::https::Proxy \"$https_proxy\";" | sudo tee -a /etc/apt/apt.conf.d/99proxy.conf
    fi
    for line in "${PPA_APT_CONF[@]}"; do
        if [[ -n "$line" ]]; then
            echo "$line" | sudo tee -a /etc/apt/apt.conf.d/99proxy.conf
        fi
    done

    sudo apt update -y
    sudo apt upgrade -y --allow-downgrades
    if [[ "$os_version" =~ "22" ]]; then
	    sudo dpkg -i --force-all /var/cache/apt/archives/libgl1-mesa-dri_24.0.5*.deb
	    sudo apt --fix-broken install -y
    fi

    $LOGD "${FUNCNAME[0]} end"
}

function install_userspace_pkgs() {
    $LOGD "${FUNCNAME[0]} begin"

    # bsp packages as per Intel bsp overlay release
    local overlay_packages=(
    vim ocl-icd-libopencl1 curl openssh-server net-tools gir1.2-gst-plugins-bad-1.0 gir1.2-gst-plugins-base-1.0 gir1.2-gstreamer-1.0 gir1.2-gst-rtsp-server-1.0 gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-opencv gstreamer1.0-plugins-bad gstreamer1.0-plugins-bad-apps gstreamer1.0-plugins-base gstreamer1.0-plugins-base-apps gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-pulseaudio gstreamer1.0-qt5 gstreamer1.0-rtsp gstreamer1.0-tools gstreamer1.0-vaapi gstreamer1.0-wpe gstreamer1.0-x intel-media-va-driver-non-free jhi jhi-tests itt-dev itt-staticdev libmfx1 libmfx-dev libmfx-tools libd3dadapter9-mesa libd3dadapter9-mesa-dev libdrm-amdgpu1 libdrm-common libdrm-dev libdrm-intel1 libdrm-nouveau2 libdrm-radeon1 libdrm-tests libdrm2 libegl-mesa0 libegl1-mesa libegl1-mesa-dev libgbm-dev libgbm1 libgl1-mesa-dev libgl1-mesa-dri libgl1-mesa-glx libglapi-mesa libgles2-mesa libgles2-mesa-dev libglx-mesa0 libgstrtspserver-1.0-dev libgstrtspserver-1.0-0 libgstreamer-gl1.0-0 libgstreamer-opencv1.0-0 libgstreamer-plugins-bad1.0-0 libgstreamer-plugins-bad1.0-dev libgstreamer-plugins-base1.0-0 libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-0 libgstreamer-plugins-good1.0-dev libgstreamer1.0-0 libgstreamer1.0-dev libigdgmm-dev libigdgmm12 libigfxcmrt-dev libigfxcmrt7 libmfx-gen1.2 libosmesa6 libosmesa6-dev libtpms-dev libtpms0 libva-dev libva-drm2 libva-glx2 libva-wayland2 libva-x11-2 libva2 libwayland-bin libwayland-client0 libwayland-cursor0 libwayland-dev libwayland-doc libwayland-egl-backend-dev libwayland-egl1 libwayland-egl1-mesa libwayland-server0 libweston-9-0 libweston-9-dev libxatracker-dev libxatracker2 mesa-common-dev mesa-utils mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers libvpl-dev libmfx-gen-dev onevpl-tools qemu-guest-agent va-driver-all vainfo weston xserver-xorg-core swtpm swtpm-tools bmap-tools adb autoconf automake libtool cmake g++ gcc git intel-gpu-tools libssl3 libssl-dev make mosquitto mosquitto-clients build-essential apt-transport-https default-jre ffmpeg git-lfs gnuplot lbzip2 libglew-dev libglm-dev libsdl2-dev mc openssl pciutils python3-pandas python3-pip python3-seaborn terminator vim wmctrl wayland-protocols gdbserver ethtool msr-tools powertop linuxptp lsscsi tpm2-tools tpm2-abrmd binutils cifs-utils i2c-tools xdotool gnupg lsb-release intel-igc-core intel-igc-opencl intel-opencl-icd intel-level-zero-gpu ethtool iproute2 socat spice-client-gtk
    )
    if [[ -n $LINUX_FW_PPA_VER ]]; then
        overlay_packages+=("linux-firmware=$LINUX_FW_PPA_VER")
    else
        overlay_packages+=("linux-firmware")
    fi

    # for SPICE with SRIOV cursor support
    overlay_packages+=("spice-vdagent")

    # install bsp overlay packages
    for package in "${overlay_packages[@]}"; do
        if [[ -n ${package+x} && -n $package ]]; then
            echo "Installing overlay package: $package"
            sudo apt install -y --allow-downgrades "$package"
        fi
    done

    # other non overlay packages
    for package in "${PACKAGES_ADD_INSTALL[@]}"; do
        if [[ -n ${package+x} && -n $package ]]; then
            echo "Installing package: $package"
            sudo apt install -y --allow-downgrades "$package"
        fi
    done

    $LOGD "${FUNCNAME[0]} end"
}

function disable_auto_upgrade() {
    $LOGD "${FUNCNAME[0]} begin"

    # Stop existing upgrade service
    sudo systemctl stop unattended-upgrades.service
    sudo systemctl disable unattended-upgrades.service
    sudo systemctl mask unattended-upgrades.service

    auto_upgrade_config=("APT::Periodic::Update-Package-Lists"
                         "APT::Periodic::Unattended-Upgrade"
                         "APT::Periodic::Download-Upgradeable-Packages"
                         "APT::Periodic::AutocleanInterval")

    # Disable auto upgrade
    for config in "${auto_upgrade_config[@]}"; do
        if [[ ! $(cat /etc/apt/apt.conf.d/20auto-upgrades) =~ $config ]]; then
            echo -e "$config \"0\";" | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades
        else
            sudo sed -i "s/$config \"1\";/$config \"0\";/g" /etc/apt/apt.conf.d/20auto-upgrades
        fi
    done
    $LOGD "${FUNCNAME[0]} end"
}

function update_cmdline() {
    $LOGD "${FUNCNAME[0]} begin"
    local updated=0
    local cmdline
    local drm_drv

    if [[ -z "${DRM_DRV_SELECTED+x}" || -z "$DRM_DRV_SELECTED" ]]; then
        drm_drv="i915"
        set_drm_drv "i915" || return 255
    else
        drm_drv="$DRM_DRV_SELECTED"
    fi

    if [[ "$RT" == "0" ]]; then
        cmds=("$drm_drv.force_probe=*"
              "$drm_drv.enable_guc=(0x)?(0)*3"
              "$drm_drv.max_vfs=(0x)?(0)*0"
              "udmabuf.list_limit=8192")
    else
        cmds=("$drm_drv.force_probe=*"
              "$drm_drv.enable_guc=(0x)?(0)*3"
              "$drm_drv.max_vfs=(0x)?(0)*0"
              "udmabuf.list_limit=8192"
              "processor.max_cstate=0"
              "intel.max_cstate=0"
              "processor_idle.max_cstate=0"
              "intel_idle.max_cstate=0"
              "clocksource=tsc"
              "tsc=reliable"
              "nowatchdog"
              "intel_pstate=disable"
              "idle=poll"
              "noht"
              "isolcpus=1"
              "rcu_nocbs=1"
              "rcupdate.rcu_cpu_stall_suppress=1"
              "rcu_nocb_poll"
              "irqaffinity=0"
              "$drm_drv.enable_rc6=0"
              "$drm_drv.enable_dc=0"
              "$drm_drv.disable_power_well=0"
              "mce=off"
              "hpet=disable"
              "numa_balancing=disable"
              "igb.blacklist=no"
              "efi=runtime"
              "art=virtallow"
              "iommu=pt"
              "nmi_watchdog=0"
              "nosoftlockup"
              "console=tty0"
              "console=ttyS0,115200n8"
              "intel_iommu=on")
    fi

    cmdline=$(sed -n -e "/.*\(GRUB_CMDLINE_LINUX=\).*/p" /etc/default/grub)
    cmdline=$(awk -F '"' '{print $2}' <<< "$cmdline")

    if [[ "${#DRM_DRV_SUPPORTED[@]}" -gt 1 ]]; then
        for drv in "${DRM_DRV_SUPPORTED[@]}"; do
            cmdline=$(sed -r -e "s/\<modprobe\.blacklist=$drv\>//g" <<< "$cmdline")
        done
        for drv in "${DRM_DRV_SUPPORTED[@]}"; do
            if [[ "$drv" != "$drm_drv" ]]; then
                $LOGD "INFO: force $drm_drv drm driver over others"
                cmds+=("modprobe.blacklist=$drv")
            fi
        done
    fi

    for cmd in "${cmds[@]}"; do
        if [[ ! "$cmdline" =~ $cmd ]]; then
            # Special handling for drm driver
            if [[ "$cmd" == "$drm_drv.enable_guc=(0x)?(0)*3" ]]; then
                for drv in "${DRM_DRV_SUPPORTED[@]}"; do
                    cmdline=$(sed -r -e "s/\<$drv.enable_guc=(0x)?([A-Fa-f0-9])*\>//g" <<< "$cmdline")
                done
                cmd="$drm_drv.enable_guc=0x3"
            fi
            if [[ "$cmd" == "$drm_drv.max_vfs=(0x)?(0)*0" ]]; then
                for drv in "${DRM_DRV_SUPPORTED[@]}"; do
                    cmdline=$(sed -r -e "s/\<$drv.max_vfs=(0x)?([0-9])*\>//g" <<< "$cmdline")
                done
                cmd="$drm_drv.max_vfs=0"
            fi

            cmdline="$cmdline $cmd"
            updated=1
        fi
    done

    if [[ "$updated" -eq 1 ]]; then
        sudo sed -i -r -e "s/(GRUB_CMDLINE_LINUX=).*/GRUB_CMDLINE_LINUX=\" $cmdline \"/" /etc/default/grub
        sudo update-grub
    fi
    $LOGD "${FUNCNAME[0]} end"
}

function update_ubuntu_cfg() {
    $LOGD "${FUNCNAME[0]} begin"
    # Enable reading of dmesg
    if ! grep -Fq 'kernel.dmesg_restrict = 0' /etc/sysctl.d/99-kernel-printk.conf; then
        echo 'kernel.dmesg_restrict = 0' | sudo tee -a /etc/sysctl.d/99-kernel-printk.conf
    fi

    # Setup SRIOV graphics
    # Switch to Xorg
    sudo sed -i "s/\#WaylandEnable=false/WaylandEnable=false/g" /etc/gdm3/custom.conf
    if ! grep -Fq 'needs_root_rights=no' /etc/X11/Xwrapper.config; then
        echo 'needs_root_rights=no' | sudo tee -a /etc/X11/Xwrapper.config
    fi
    if ! grep -Fq 'MESA_LOADER_DRIVER_OVERRIDE=pl111' /etc/environment; then
        echo 'MESA_LOADER_DRIVER_OVERRIDE=pl111' | sudo tee -a /etc/environment
    fi
    # Enable for SW cursor
    if ! grep -Fq 'VirtIO-GPU' /usr/share/X11/xorg.conf.d/20-modesetting.conf; then
        sudo tee -a "/usr/share/X11/xorg.conf.d/20-modesetting.conf" &>/dev/null <<EOF
Section "Device"
Identifier "VirtIO-GPU"
Driver "modesetting"
#BusID "PCI:0:4:0" #virtio-gpu
Option "SWcursor" "false"
EndSection
EOF
    fi
    # Add script to dynamically enable/disable SW cursor
    if ! grep -Fq '/dev/virtio-ports/com.redhat.spice.0' /usr/local/bin/setup_sw_cursor.sh; then
        sudo tee -a "/usr/local/bin/setup_sw_cursor.sh" &>/dev/null <<EOF
#!/bin/bash
if [[ -e /dev/virtio-ports/com.redhat.spice.0 ]]; then
    if grep -F '"SWcursor" "true"' /usr/share/X11/xorg.conf.d/20-modesetting.conf; then
        sed -i "s/Option \"SWcursor\" \"true\"/Option \"SWcursor\" \"false\"/g" /usr/share/X11/xorg.conf.d/20-modesetting.conf
    fi
else
    if grep -F '"SWcursor" "false"' /usr/share/X11/xorg.conf.d/20-modesetting.conf; then
        sed -i "s/Option \"SWcursor\" \"false\"/Option \"SWcursor\" \"true\"/g" /usr/share/X11/xorg.conf.d/20-modesetting.conf
    fi
fi
EOF
        sudo chmod 744 /usr/local/bin/setup_sw_cursor.sh
    fi
    # Add startup service to run script during boot up
    if ! grep -Fq 'ExecStart=/usr/local/bin/setup_sw_cursor.sh' /etc/systemd/system/setup_sw_cursor.service; then
        sudo tee -a "/etc/systemd/system/setup_sw_cursor.service" &>/dev/null <<EOF
[Unit]
Description=Script to dynamically enable/disable SW cursor for SPICE gstreamer
After=sysinit.target
[Service]
ExecStart=/usr/local/bin/setup_sw_cursor.sh
[Install]
WantedBy=default.target
EOF
        sudo chmod 664 /etc/systemd/system/setup_sw_cursor.service
        sudo systemctl daemon-reload
        if [[ "$FORCE_SW_CURSOR" == "1" ]]; then
            sudo systemctl enable setup_sw_cursor.service
        fi
    fi
    # Disable GUI for RT guest
    if [[ "$RT" == "1" ]]; then
        systemctl set-default multi-user.target
    fi
    $LOGD "${FUNCNAME[0]} end"
}

function show_help() {
    printf "%s [-k kern_deb_path | -kp kern_ver] [-fw fw_ver] [-drm drm_drv] [--no-install-bsp] [--rt]\n" "$(basename "${BASH_SOURCE[0]}")"
    printf "Options:\n"
    printf "\t-h\tshow this help message\n"
    printf "\t-k\tpath to location of bsp kernel files linux-headers.deb and linux-image.deb\n"
    printf "\t-kp\tversion string of kernel overlay to select from Intel PPA. Eg \"6.3-intel\"\n"
    printf "\t-fw\tversion string of linux-firmware overlay to select from Intel PPA. Eg \"20220329.git681281e4-0ubuntu3.17-1ppa1~jammy3\"\n"
    printf "\t--rt\tinstall for Ubuntu RT version\n"
    printf "\t--no-bsp-install\tDo not preform bsp overlay related install(kernel and userspace)\n"
    printf "\t-drm\tspecify drm driver to use for Intel gpu:\n"
    for d in "${DRM_DRV_SUPPORTED[@]}"; do
        printf '\t\t\t%s\n' "$(basename "$d")"
    done
}

function parse_arg() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|-\?|--help)
                show_help
                exit 0
                ;;

            -k)
                KERN_INSTALL_FROM_PPA=0
                KERN_PATH=$2
                shift
                ;;

            -kp)
                KERN_INSTALL_FROM_PPA=1
                KERN_PPA_VER=$2
                shift
                ;;

            -fw)
                LINUX_FW_PPA_VER=$2
                shift
                ;;

            -drm)
                set_drm_drv "$2" || return 255
                shift
                ;;

            --rt)
                RT=1
                ;;

            --no-bsp-install)
                NO_BSP_INSTALL=1
                ;;

            --force-sw-cursor)
                FORCE_SW_CURSOR=1
                ;;

            -?*)
                $LOGE "Error: Invalid option: $1"
                show_help
                return 255
                ;;
            *)
                $LOGE "Error: Unknown option: $1"
                return 255
                ;;
        esac
        shift
    done
}

#-------------    main processes    -------------
trap 'echo "Error line ${LINENO}: $BASH_COMMAND"' ERR

parse_arg "$@" || exit 255

if [[ "$NO_BSP_INSTALL" -ne "1" ]]; then
    # Install PPA
    setup_overlay_ppa || exit 255

    # Install bsp kernel
    if [[ "$KERN_INSTALL_FROM_PPA" -eq "0" ]]; then
        install_kernel_from_deb "$KERN_PATH" || exit 255
    else
        install_kernel_from_ppa "$KERN_PPA_VER" || exit 255
    fi
    # Install bsp userspace
    install_userspace_pkgs || exit 255
fi
disable_auto_upgrade || exit 255
update_cmdline || exit 255
update_ubuntu_cfg || exit 255

echo "Done: \"$(realpath "${BASH_SOURCE[0]}") $*\""
