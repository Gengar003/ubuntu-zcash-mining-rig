#!/usr/bin/env bash

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
cp /tmp/miner ~/bin/miner-zec-ewbf

# test ewbfminer
miner-zec-ewbf --server eu1-zcash.flypool.org --user ${ZCASH_ADDRESS}.ewbf_test --pass x --port 3333 --cuda_devices 0 --fee 0 --intensity 64 &
sleep 10
sudo pkill miner-zec-ewbf

# install ewbfminer as service
CURR_USER=$(whoami)
HOSTNAME=$(hostname)
GDM_USER=$(id -u gdm)

if [ -z "FAN_DURING_MINING" ]; then
	# no "fan during mining" specified; leave fans on auto.
	sudo cat <<- EOF > /tmp/miner-zec-ewbf.service
	[Unit]
	Description=EWBF ZCash Miner
	After=network.target
	
	[Service] 
	Type=simple
	User=${CURR_USER}
	WorkingDirectory=/home/${CURR_USER}/bin
	ExecStart=/home/${CURR_USER}/bin/miner-zec-ewbf --server eu1-zcash.flypool.org --user ${ZCASH_ADDRESS}.${HOSTNAME} --pass x --port 3333 --cuda_devices 0 1 --fee 0 --intensity 64
	Restart=always
	
	[Install] 
	WantedBy=multi-user.target
	EOF
else
	# user specified a "fan during mining" setting.
	sudo cat <<- EOF > /tmp/miner-zec-ewbf.service
[Unit]
	Description=EWBF ZCash Miner
	After=network.target
	
	[Service]
	Environment=ZCASH_ADDRESS=${ZCASH_ADDRESS}
	Environment=FAN_DURING_MINING=${FAN_DURING_MINING}
	
	Environment=DISPLAY=:1
	Environment=XAUTHORITY=/run/user/${GDM_USER}/gdm/Xauthority
	
	Type=simple
	User=${CURR_USER}
	WorkingDirectory=/home/${CURR_USER}/bin
	
	ExecStartPre=/bin/bash --login -c "/usr/bin/nvidia-settings -a '[gpu:0]/GPUFanControlState=1' -a \\"[fan:0]/GPUTargetFanSpeed=\${FAN_DURING_MINING}\\" -a '[gpu:1]/GPUFanControlState=1' -a \\"[fan:1]/GPUTargetFanSpeed=\${FAN_DURING_MINING}\\""
	
	ExecStart=/bin/bash --login -c "miner-zec-ewbf --server eu1-zcash.flypool.org --user \${ZCASH_ADDRESS}.kinglear --pass x --port 3333 --cuda_devices 0 1 --fee 0 --intensity 64"
	
	ExecStopPost=/usr/bin/nvidia-settings -a "[gpu:0]/GPUFanControlState=0" -a "[gpu:1]/GPUFanControlState=0"
	
	Restart=always
	
	[Install]
	WantedBy=multi-user.target
	EOF
fi

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

