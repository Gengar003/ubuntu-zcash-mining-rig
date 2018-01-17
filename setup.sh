#!/usr/bin/env bash

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

