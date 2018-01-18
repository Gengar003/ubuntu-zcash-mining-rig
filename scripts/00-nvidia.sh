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
LATEST_NVIDIA_DRIVER=$(sudo ubuntu-drivers devices | awk '/driver.*?nvidia/{print $3}' | sort -r | head -n 1)
LATEST_CUDA_NVIDIA_DRIVER=$(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances --no-pre-depends cuda | gawk 'match($0, /(nvidia-[0-9]+)/, ary) {print ary[1]}' | sort -r | head -n 1)

if [ -e ~/.nvidia-driver ]; then
	# nvidia drivers have been installed BY THIS SCRIPT previously.
	CURRENT_NVIDIA_DRIVER=$(cat ~/.nvidia-driver)

	if [ "${CURRENT_NVIDIA_DRIVER}" != "${LATEST_CUDA_NVIDIA_DRIVER}" ]; then
		# cuda wants a different nvidia driver version than what is installed.
		# need to purge all nvidia drivers and re-install
		rm -f ~/.nvidia-driver
		sudo apt-get purge -y nvidia-*
	fi
else
	# nvidia drivers have not been installed by this script before
	# purge all existing nvidia drivers.
	sudo apt-get purge -y nvidia-*
fi

# sometimes nvidia drivers run ahead of what CUDA supports. Don't install them.
# sudo apt-get install -y ${NVIDIA_DRIVER}

# install (latest) CUDA drivers
sudo apt-get install -y cuda nvidia-settings

# Remove non-nvidia drivers
sudo apt-get purge -y xserver-xorg-video-nouveau

# configure NVidia drivers
sudo nvidia-xconfig --cool-bits=4 # enable direct fan control
sudo nvidia-xconfig --enable-all-gpus #(you can figure this one out)

# configure support for headless operation (there probably won't be a monitor on EVERY GPU)
sudo nvidia-xconfig --allow-empty-initial-configuration

# set "nomodeset" so GRUB can still boot to a GUI if someone does connect a monitor
# https://askubuntu.com/questions/38780/how-do-i-set-nomodeset-after-ive-already-installed-ubuntu
sudo sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/ c\GRUB_CMDLINE_LINUX_DEFAULT="nosplash nomodeset"' /etc/default/grub

# only NEEDED if using full-disk encryption; appears harmless if not
sudo update-initramfs -u

#####
# Housekeeping
#####

# remove useless things that the internet says cause trouble with NVidia
sudo apt-get remove -y fwupd

JUST_INSTALLED_NVIDIA_VERSION=$(dpkg -l | awk -F '[ -]' '/nvidia-[0-9]+/{print $4}' | sort -r | head -n 1)

if [ -e ~/.nvidia-version ] && [ "${JUST_INSTALLED_NVIDIA_VERSION}" == "$(cat ~/.nvidia-version)" ]; then
	# The installer has run previously, because the nvidia version is recorded.
	# The current nvidia drivers are also the latest.
	# there is no need to reboot.
	# 62 wide, 60 usable, 58 used
	cat <<- EOF
	+===========================================================+
	| NVidia drivers installed                                  |
	+===========================================================+
	EOF
else
	# Either there is no record of nvidia driver installation (meaning probably the first time)
	# or they are outdated (meaning we probably installed new ones)
	# need to reboot.

	echo "${JUST_INSTALLED_NVIDIA_VERSION}" > ~/.nvidia-version

	# 62 wide, 60 usable, 58 used
	cat <<- EOF
	+===========================================================+
	| NVidia drivers installed                                  |
	|                                                           |
	| It looks like this version hasn't been installed before.  |
	| Your computer will now reboot.                            |
	|                                                           |
	| Please run these scripts again when you log back in.      |
	| You will not have to reboot a second time.                |
	+===========================================================+
	EOF

	read -p "Press any key to reboot... "

	sudo reboot
fi
