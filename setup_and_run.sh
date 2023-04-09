#! /usr/bin/bash

# Guide         https://computingforgeeks.com/how-to-run-macos-on-kvm-qemu
# Github repo   https://github.com/foxlet/macOS-Simple-KVM


# Install apt packages

## Package qemu-kvm is virtual, replace it with qemu-system-x86
## after having consulted grep-status -FProvides,Package -sPackage,Provides,Status qemu-kvm
packages=(qemu-system-x86 libvirt-daemon qemu-system qemu-utils python3 python3-pip bridge-utils virtinst libvirt-daemon-system virt-manager)
toBeInstalled=()
for package in "${packages[@]}"; do
    dpkg --audit "$package" || toBeInstalled+=("$package")
done
if (( ${#toBeInstalled[@]} != 0 )); then
    echo ${#toBeInstalled[@]} packages to be installed:
    read -p "Press Enter to continue" </dev/tty
    sudo apt update
    sudo apt install ${toBeInstalled[*]}
fi


## Ensure the vhost_net module is loaded
vhostCount=`lsmod | grep vhost | wc -l`
if (( vhostCount == 0)); then
    echo Please load the vhost_net module
    read -p "Press Enter to continue" </dev/tty
    sudo modprobe vhost_net
fi


## Start kernel based VM service (KVM)
### QEMU can make use of KVM
### You can call virt-manager
systemctl is-active --quiet libvirtd || (
    echo Please start and enable the KVM service:
    read -p "Press Enter to continue" </dev/tty
    sudo systemctl start  libvirtd
    sudo systemctl enable libvirtd
)


## If the installer and the macOS disk are missing, download the installer
[ -e BaseSystem.img ] || [ -e macOS.qcow2 ] || ./jumpstart.sh


## Remove the compressed MacOS installer image
#[- d tools/FetchMacOS/BaseSystem ] && rm -rf tools/FetchMacOS/BaseSystem


## Check or create macOS disk
[ -e macOS.qcow2 ] || qemu-img create -f qcow2 macOS.qcow2 50G


## Start Clover (install or macOS)
./basic.sh


## Operate Clover
### For install
###   Use arrow keys to select the upper central macOS disk icon and press enter
###   Disk Utility: format 50 GB disk
###   Reinstall. MacOS will reboot, the progress bar then hangs at the end for 2 hours
### For macOS
###   Use arrow keys to select "Boot from macOS" and press enter



## Instead of QEMU, you’d like to import the setup into Virt-Manager for further configuration, just run:
#sudo ./make.sh --add
## After running the command above, add macOS.qcow2 as storage in the properties of the newly added entry for VM.
