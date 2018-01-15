#!/usr/bin/env bash

set -e

./scripts/00-nvidia.sh "$@"
./scripts/10-rig.sh "$@"
./scripts/20-miner.sh "$@"

# 62 wide, 60 usable, 58 used
cat << EOF
+===========================================================+
| ZCASH MINING RIG READY!                                   |
+===========================================================+
EOF

