import subprocess
from checks import AgentCheck

class SystemdUnitCheck(AgentCheck):

	def check(_self, _instance):
		unit_status = subprocess.call([
			"systemctl",
			"is-active",
			"--quiet",
			_instance.get( "name" ) ])

		service_status = AgentCheck.UNKNOWN

		if 0 == unit_status:
			service_status = AgentCheck.OK
		elif 3 == unit_status:
			service_status = AgentCheck.CRITICAL

		_self.service_check(
			"systemd." + _instance.get( "name" ),
			service_status )
