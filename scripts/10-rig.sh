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
sudo apt-get install -y jq curl openssh-server openssh-client ubuntu-drivers-common

# remove other useless things
sudo apt-get -y autoremove

# upgrade what we can
sudo apt-get -y upgrade

# 62 wide, 60 usable, 58 used
cat << EOF
+===========================================================+
| Mining Rig Configured                                     |
+===========================================================+
EOF

