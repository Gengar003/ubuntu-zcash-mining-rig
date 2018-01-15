import subprocess
import re
from checks import AgentCheck

class SystemdUnitCheck(AgentCheck):

	def check(_self, _instance):
		_self.gauge(
			"systemd." + _instance.get( "name" ) + ".is-active",
			subprocess.call([
				"systemctl",
				"is-active",
				"--quiet",
				_instance.get( "name" ) ]) )
