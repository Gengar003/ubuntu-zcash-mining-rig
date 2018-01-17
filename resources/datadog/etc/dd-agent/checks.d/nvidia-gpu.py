import subprocess
import re
from checks import AgentCheck

class NVidiaGPUCheck(AgentCheck):

	def check(_self, _instance):
		gpu_metrics_output = subprocess.check_output([
			"nvidia-smi",
			"--query-gpu=index," + _self.init_config.get( "gpu_metric_names" ),
			"--format=csv" ])
		gpu_metrics_list = gpu_metrics_output.split("\n")

		for gpu_metrics_line in gpu_metrics_list[1:]:
			if len( gpu_metrics_line.strip() ) != 0:
				gpu_metric_list = gpu_metrics_line.split(", ")
				_self.report_gpu_stats(
					gpu_metric_list[0],
					_self.init_config.get( "gpu_metric_names" ).split(","),
					gpu_metric_list[1:] )

	def report_gpu_stats(_self, _gpu_index, _metric_names, _metric_values):
		print "reporting on GPU [" + str( _gpu_index ) + "]..."
		if len( _metric_names ) != len( _metric_values ):
			raise Exception( "Different number of GPU metric names from GPU metric values. Names: [" + str( _metric_names ) + "], values: [" + str( _metric_values ) + "]" )
		for gpu_metric, gpu_value in zip( _metric_names, _metric_values ):
			_self.gauge(
				"gpu." + gpu_metric,
				re.sub( r"[^0-9.-]", "", gpu_value ),
				tags=["gpu:" + str( _gpu_index ) ] )
