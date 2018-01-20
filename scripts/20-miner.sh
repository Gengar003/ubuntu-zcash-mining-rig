#!/usr/bin/env bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#####
# Global Settings
#####

#####
# Read Input
#####

while [[ $# -gt 0 ]]; do

	key="$1"

	case $key in
		--zcash-address|-z)
		ZCASH_ADDRESS="$2"
		shift
		;;
		--fan-during-mining|-f)
		FAN_DURING_MINING="$2"
		shift
		;;
	esac

	shift
done

#####
# Compute Input
#####

#####
# Validate Input
#####

if [ -z "${ZCASH_ADDRESS}" ]; then
	echo "ERROR: Please specify the ZCash t-address that should receive mining proceeds."
	exit 1
fi

if [ -n "${FAN_DURING_MINING}" ]; then
	if [ ${FAN_DURING_MINING} -lt 0 ] || [ ${FAN_DURING_MINING} -gt 100 ]; then
		echo "ERROR: --fan-during-mining must be in the range [0,100]; saw [${FAN_DURING_MINING}]"
		exit 1
	elif [ ${FAN_DURING_MINING} -eq 0 ]; then
		echo "WARNING: --fan-during-mining set to 0! I hope you have some other cooling solution!"
	fi
fi

set -x
set -e

#####
# Miner Setup
#####

# install ewbfminer
EWBF_URL=$(curl --silent https://api.github.com/repos/nanopool/ewbf-miner/releases | jq -r '.[0].assets[] | select( .name | contains("Linux") ) | .browser_download_url')
wget -qO /tmp/ewbf.tar.gz "${EWBF_URL}"
tar -zxvf /tmp/ewbf.tar.gz -C /tmp/

# install miner
sudo mkdir -p /opt/miners/zec
sudo cp /tmp/miner /opt/miners/zec/ewbf
sudo chmod a+rx /opt/miners/zec/ewbf

# test ewbfminer
/opt/miners/zec/ewbf --server eu1-zcash.flypool.org --user ${ZCASH_ADDRESS}.ewbf_test --pass x --port 3333 --cuda_devices 0 --fee 0 --intensity 64 &
sleep 10
sudo pkill ewbf

# install ewbfminer as service
export MINER_USER=$(whoami)
export HOSTNAME=$(hostname)

export EXPORTED_ZCASH_ADDRESS=${ZCASH_ADDRESS}

if [ -z "${FAN_DURING_MINING}" ]; then
	# no "fan during mining" specified; leave fans on auto.
	envsubst '${MINER_USER},${HOSTNAME},${EXPORTED_ZCASH_ADDRESS}' < ../resources/miner/etc/systemd/system/miner-zec-ewbf.service.template > /tmp/miner-zec-ewbf.service
else
	# user specified a "fan during mining" setting.
	# nvidia-settings must be used, and it must be given a "working" display.

	SET_GPU_FANS_ON_START="/usr/bin/nvidia-settings"
	SET_GPU_FANS_ON_END="/usr/bin/nvidia-settings"
	GPU_INDICIES=""

	HEADLESS_INSTALL="false"

	if id -u gdm >/dev/null 2>&1; then
		# This is (probably) Ubuntu "Desktop"
		HEADLELSS_INSTALL="false"
	elif id -u lightdm > /dev/null 2>&1; then
		# This is (probably) Ubuntu "Server"
		HEADLESS_INSTALL="true"
	else
		# This probably isn't going to work.
		echo "ERROR: Explicit fan control requested, but this requires nvidia-settings which requires a display, and I couldn't find any displays that I knew would work."
		echo -e "\tConsider not using explicit fan control (remove the --fan-during-mining flag)"
		exit 1
	fi

	if [ true = "${HEADLESS_INSTALL}" ]; then
		export NVIDIA_FAN_DISPLAY=:0
		export NVIDIA_FAN_XAUTHORITY="/var/run/lightdm/root/${NVIDIA_FAN_DISPLAY}"
	else
		export NVIDIA_FAN_DISPLAY=:0
		export NVIDIA_FAN_XAUTHORITY="/run/user/$(id -u gdm)/gdm/Xauthority"
	fi

	export EXPORTED_FAN_DURING_MINING=${FAN_DURING_MINING}

	for gpu_index in $(nvidia-smi --query-gpu=index --format=csv,noheader,nounits); do
		export SET_GPU_FANS_ON_START="${SET_GPU_FANS_ON_START} -a \"[gpu:${gpu_index}]/GPUFanControlState=1\" -a \"[fan:${gpu_index}]/GPUTargetFanSpeed=\${FAN_DURING_MINING}\""
		export SET_GPU_FANS_ON_END="${SET_GPU_FANS_ON_END} -a \"[gpu:${gpu_index}]/GPUFanControlState=0\""
		export GPU_INDICIES="${GPU_INDICIES} ${gpu_index} "
	done

	if [ true = "${HEADLESS_INSTALL}" ]; then
		export SET_GPU_FANS_ON_START="/usr/bin/X & sleep 5; ${SET_GPU_FANS_ON_START}; sleep 5; /usr/bin/pkill X"
		export SET_GPU_FANS_ON_END="/usr/bin/X & sleep 5; ${SET_GPU_FANS_ON_END}; sleep 5; /usr/bin/pkill X"
	fi

	envsubst '${MINER_USER},${HOSTNAME},${EXPORTED_ZCASH_ADDRESS},${EXPORTED_FAN_DURING_MINING},${NVIDIA_FAN_DISPLAY},${NVIDIA_FAN_XAUTHORITY},${SET_GPU_FANS_ON_START},${SET_GPU_FANS_ON_END},${GPU_INDICIES}' \
		< ../resources/miner/etc/systemd/system/miner-zec-ewbf-fan.service.template \
		> /tmp/miner-zec-ewbf.service
fi

echo "===================="
cat /tmp/miner-zec-ewbf.service
echo "===================="

sudo mv /tmp/miner-zec-ewbf.service /etc/systemd/system/miner-zec-ewbf.service
sudo systemctl daemon-reload
sudo systemctl enable miner-zec-ewbf

# 62 wide, 60 usable, 58 used
cat << EOF
+===========================================================+
| EWBF ZCash Miner installed as a system service            |
|                                                           |
| Edit /etc/systemd/system/miner-zec-ewbf.service to make   |
| changes.                                                  |
|                                                           |
| Run 'systemctl start miner-zec-ewbf' to start now!        |
+===========================================================+
EOF

#!/usr/bin/env bash

