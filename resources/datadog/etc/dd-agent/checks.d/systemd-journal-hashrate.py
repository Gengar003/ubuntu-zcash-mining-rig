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

import datetime
import re
import subprocess
import time

from checks import AgentCheck

class SystemJournalHashRateCheck(AgentCheck):

	def check(_self, _instance):

		oldest_allowed_logline=	datetime.datetime.now() - datetime.timedelta(minutes = int(_self.init_config.get( "max_log_line_age_minutes" ) ) )
		log_output="undefined"
		try:
			log_output = subprocess.check_output([
				"journalctl",
				"-u",
				_instance.get( "unit" ),
				"--lines",
				"100",
				"--since",
				oldest_allowed_logline.strftime(
					"%Y-%m-%d %H:%M:%S" ) ])
		except:
			print "Error retrieving logs from journalctl. Log output: [" + log_output + "]"
			raise

		pattern = re.compile( _instance.get( "gpu_hashrate_regex" ) )

		log_lines = log_output.split( "\n" )

		for line in reversed( log_lines ):
			if pattern.search( line.strip() ):
				for (gpu_index, gpu_hashrate) in re.findall( pattern, line.strip() ):
					_self.gauge(
						"gpu.hashrate",
						gpu_hashrate,
						tags=["gpu:" + gpu_index, "systemd.unit:" + _instance.get( "unit" ) ] )
				break
