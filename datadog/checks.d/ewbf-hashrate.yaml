import datetime
import re
import subprocess
import time

from checks import AgentCheck

class EWBFHashRateCheck(AgentCheck):

	def check(_self, _instance):

		oldest_allowed_logline=	datetime.datetime.now() - datetime.timedelta(minutes = int(_self.init_config.get( "max_log_line_age_minutes" ) ) )
		ewbf_log_output="undefined"
		try:
			ewbf_log_output = subprocess.check_output([
				"journalctl",
				"-u",
				"miner-zec-ewbf",
				"--lines",
				"100",
				"--since",
				oldest_allowed_logline.strftime(
					"%Y-%m-%d %H:%M:%S" ) ])
		except:
			print "Log output: [" + ewbf_log_output + "]"
			raise
			# TODO: datadog error

		pattern = re.compile( _self.init_config.get( "ewbf_gpu_hashrate_regex" ) )

		ewbf_log_lines = ewbf_log_output.split( "\n" )

		for line in reversed( ewbf_log_lines ):
			if pattern.search( line.strip() ):
				for (gpu_index, gpu_hashrate) in re.findall( pattern, line.strip() ):
					_self.gauge(
						"gpu.hashes",
						gpu_hashrate,
						tags=["gpu:" + gpu_index] )
				break
