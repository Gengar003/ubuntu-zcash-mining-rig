#!/usr/bin/env bash

set -e

./scripts/00-nvidia.sh "$@"
./scripts/10-rig.sh "$@"
./scripts/20-miner.sh "$@"
