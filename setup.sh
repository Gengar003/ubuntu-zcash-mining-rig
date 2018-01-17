#!/usr/bin/env bash

if [ "0" == $(id -u) ]; then
	echo "ERROR: Do not run these scripts as 'root'."
	exit 1
fi

set -e

cd scripts

./00-nvidia.sh "$@"
./10-rig.sh "$@"
./20-miner.sh "$@"
./30-datadog.sh "$@"

# 62 wide, 60 usable, 58 used
cat << EOF
+===========================================================+
| ZCASH MINING RIG READY!                                   |
+===========================================================+
EOF

