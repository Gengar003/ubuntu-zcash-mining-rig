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
		--datadog-api-key|-d)
		DATADOG_API_KEY="$2"
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

if [ -z "${DATADOG_API_KEY}" ]; then
	# 62 wide, 60 usable, 58 used
	cat <<- EOF
	+===========================================================+
	| No DataDog API key provided                               |
	|                                                           |
	| Skipping DataDog installation for now.                    |
	+===========================================================+
	EOF

	exit 0
fi

set -x
set -e

#####
# DataDog Agent
#####
DD_API_KEY=${DATADOG_API_KEY} bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/dd-agent/master/packaging/datadog-agent/source/install_agent.sh)"

#####
# DataDog Mining Checks
#####
sudo cp -rfva ../datadog/checks.d/. /etc/dd-agent/checks.d
sudo cp -rfva ../datadog/conf.d/. /etc/dd-agent/conf.d

# reboot datadog
sudo systemctl restart datadog-agent

# 62 wide, 60 usable, 58 used
cat << EOF
+===========================================================+
| DataDog monitoring installed                              |
+===========================================================+
EOF
