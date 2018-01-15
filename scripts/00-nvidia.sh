#!/usr/bin/env bash

#####
# Global Settings
#####
NVIDIA_CUDA_REPO="http://developer.download.nvidia.com/compute/cuda/repos"

#####
# Read Input
#####

while [[ $# -gt 0 ]]; do

	key="$1"

	case $key in
		--nvidia-ubuntu-version|-v)
		NVIDIA_UBUNTU_VERSION="$2"
		shift
		;;
	esac

	shift
done

#####
# Compute Input
#####

eval `cat /etc/lsb-release`


if [ -z "${NVIDIA_UBUNTU_VERSION}" ]; then
	echo "Detecting Ubuntu version to use for NVidia drivers..."

	NVIDIA_UBUNTU_VERSION=$(echo $DISTRIB_RELEASE | tr -d '.')
	echo -e "\tUbuntu version = [${DISTRIB_RELEASE}]; using [${NVIDIA_UBUNTU_VERSION}]."
fi

#####
# Validate Input
#####


if [ -z "${NVIDIA_UBUNTU_VERSION}" ]; then
	echo "ERROR: Please specify the --nvidia-ubuntu-version to use to look for NVidia drivers."
	exit 1
else
	NVIDIA_REPO_BASE="${NVIDIA_CUDA_REPO}/ubuntu${NVIDIA_UBUNTU_VERSION}/x86_64"
	echo -e "\tFinding latest NVidia CUDA drivers at [${NVIDIA_REPO_BASE}]..."
	NVIDIA_REPO_NAME=$(wget -qO- ${NVIDIA_REPO_BASE} | grep cuda-repo-ubuntu${NVIDIA_UBUNTU_VERSION} | awk -F [\'] '{print $4}' | sort -rh | head -n 1)

	if [ -z "${NVIDIA_REPO_NAME}" ]; then
		echo "ERROR: Couldn't find CUDA drivers for Ubuntu version [${NVIDIA_UBUNTU_VERSION}]; please check [${NVIDIA_CUDA_REPO}] for an 'ubuntu${DISTRIB_RELEASE%.*}xx' directory, then run again with the '--nvidia-ubuntu-version ${DISTRIB_RELEASE%.*}xx' flag."
		exit 1
	fi
	NVIDIA_REPO_URL="${NVIDIA_REPO_BASE}/${NVIDIA_REPO_NAME}"
	echo -e "\t ... found [${NVIDIA_REPO_NAME}]"

fi

set -x
set -e

#####
# NVidia Drivers
#####

# add nvidia driver repo
sudo add-apt-repository -y ppa:graphics-drivers/ppa

# add cuda driver repo
wget --quiet --output-document="/tmp/${NVIDIA_REPO_NAME}" "${NVIDIA_REPO_URL}"
sudo dpkg -i /tmp/${NVIDIA_REPO_NAME}

# add CUDA driver repo gpg key
NVIDIA_CUDA_REPO_KEYFILE=$(wget -qO- http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1704/x86_64/ | awk -F[\'] '/.pub/{print $4}')
sudo apt-key adv --fetch-keys "${NVIDIA_REPO_BASE}/${NVIDIA_CUDA_REPO_KEYFILE}"

# RANDOM INTERNET TROUBLESHOOTING:
# kill plymouth
sudo pkill plymouth || true # (it might not be running...)

# update apt; we're ready
sudo apt-get update

# install nvidia drivers
NVIDIA_DRIVER=$(sudo ubuntu-drivers devices | awk '/driver.*?nvidia/{print $3}' | sort -r | head -n 1)
sudo apt-get install -y ${NVIDIA_DRIVER}

# install CUDA drivers
sudo apt-get install -y cuda nvidia-settings

# set "nomodeset" so we can boot
# https://askubuntu.com/questions/38780/how-do-i-set-nomodeset-after-ive-already-installed-ubuntu

# not the most elegant, but should work.
sudo sh -c "echo \"GRUB_CMDLINE_LINUX_DEFAULT=\\\"nosplash nomodeset\\\"\" >> /etc/default/grub"

# activate nvidia drivers
sudo nvidia-xconfig --cool-bits=4 # allow direct fan control
sudo update-initramfs -u # only if encrypted disk

# Remove non-nvidia drivers
# may ruin system? Skip for now.
# sudo apt-get --purge remove xserver-xorg-video-nouveau

#####
# Housekeeping
#####

# remove useless things that the internet says cause trouble with NVidia
sudo apt-get remove -y fwupd

# 62 wide, 60 usable, 58 used
cat << EOF
+===========================================================+
| NVidia drivers installed                                  |
|                                                           |
| As far as I can tell, you must actually reboot before     |
| they are guaranteed to take effect.                       |
|                                                           |
| Proceeding without rebooting may not work properly.       |
+===========================================================+
EOF

# TODO: some kind of graceful reboot
