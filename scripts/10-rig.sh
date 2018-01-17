#!/usr/bin/env bash

#####
# Read Input
#####

while [[ $# -gt 0 ]]; do

	key="$1"

	case $key in
	esac

	shift
done

#####
# Compute Input
#####

#####
# Validate Input
#####

#####
# Mining Rig Setup
#####

# setup SSH identity
[ -e ~/.ssh/id_rsa ] || ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''

# install tools we'll use later
sudo apt-get install -y jq curl openssh-server openssh-client ubuntu-drivers

# remove other useless things
sudo apt-get autoremove

# upgrade what we can
sudo apt-get upgrade

# 62 wide, 60 usable, 58 used
cat << EOF
+===========================================================+
| Mining Rig Configured                                     |
+===========================================================+
EOF

