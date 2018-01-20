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

import subprocess
from checks import AgentCheck

class SystemdUnitCheck(AgentCheck):

	def check(_self, _instance):
		unit_status = subprocess.call([
			"systemctl",
			"is-active",
			"--quiet",
			_instance.get( "unit" ) ])

		service_status = AgentCheck.UNKNOWN

		if 0 == unit_status:
			service_status = AgentCheck.OK
		elif 3 == unit_status:
			service_status = AgentCheck.CRITICAL

		_self.service_check(
			"systemd." + _instance.get( "unit" ),
			service_status,
			tags=["systemd.unit:" + _instance.get( "unit" ) ] )
