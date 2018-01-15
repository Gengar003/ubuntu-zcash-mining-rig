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

sudo cat << EOF > /tmp/miner-zec-ewbf.service
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
| Run `systemctl start miner-zec-ewbf` to start now!        |
+===========================================================+
EOF

