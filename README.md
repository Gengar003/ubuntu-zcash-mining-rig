NVidia ZCash Miner on Ubuntu
==============================

Scripts to configure an [*Ubuntu*](https://www.ubuntu.com/download) installation to mine [*ZCash*](https://z.cash/) with [*EWBF Miner*](https://github.com/nanopool/ewbf-miner) on an *NVidia* GPU, as part of the [FlyPool](http://zcash.flypool.org) mining pool.
Remote monitoring of the miner with [DataDog](https://www.datadoghq.com/) is supported if you have a DataDog account.

You've got to provide your own, internet-connected Ubuntu installation but these scripts should be able to take care of the rest.

Getting Started
==============================

Pre-Requisites
-------------------------

1. A working, contemporary Ubuntu installation. These scripts have been tested on
	1. Ubuntu Desktop 17.10
	2. ~Ubuntu Desktop 16.04~
	3. ~Ubuntu Server 17.10~
	4. ~Ubuntu Server 16.04~
2. A ZCash t-address
3. (optional) a DataDog API key for your DataDog account
4. A modern NVidia GPU

Installation
-------------------------

1. Clone this repository. You may need to run `sudo apt-get update && apt-get install git` if the installation is brand-new.
2. Run `setup.sh`
3. When setup completes successfully, run `systemctl start miner-zec-ewbf`.
4. Done!

Modules
==============================

Each module is _idempotent_: You can run them multiple times without worry about messing up your system.

`00-nvidia.sh`
-------------------------

Installs NVidia GPU and CUDA drivers.

| Command-Line Flag                | Required? | Purpose                                       |
| -------------------------------- | --------- | --------------------------------------------- |
| `--nvidia-ubuntu-version` / `-v` | ✔         | Identify the NVidia release of Ubuntu Drivers |

### `--nvidia-ubuntu-version`

NVidia drivers for ubuntu are stored at http://developer.download.nvidia.com/compute/cuda/repos.
However, they are not updated for every Ubuntu release.
It may be that the latest NVidia drivers are `1704`, but your Ubuntu installation is something newer, like `17.10`.
In this case, use the `--nvidia-ubuntu-version` flag to provide the correct identifier, e.g. `--nvidia-ubuntu-version 1704`.

The script will instruct you to do this if necessary.

`10-righ.sh`
-------------------------

Sets up the Ubuntu Linux environment for a primarily-unattended mining rig.
Installs an SSH server and upgrades all installed packages.

`20-miner.sh`
-------------------------

Installs the [EWBF CUDA ZCash Miner](https://github.com/nanopool/ewbf-miner) as a system service, connected to the [FlyPool ZCash Mining Pool](http://zcash.flypool.org/).

| Command-Line Flag            | Required? | Purpose                                         |
| ---------------------------- | --------- | ----------------------------------------------- |
| `--zcash-address` / `-z`     | ✔         | The "t-address" to send earned coins to.        |
| `--fan-during-mining` / `-f` |           | A %speed to set GPU fans to when mining starts. |

### `--fan-during-mining`

If set, the GPU fans will be set to this % of maximum possible speed when the mining service is active
and automatically managed by the GPU when mining is inactive.

If un-set, the GPU fans will be automatically managed by the GPU at all times.

This uses the `nvidia-settings` tool which can be finicky about requiring a GUI environment.
It is recommended to _not_ use this flag unless your GPUs' automatic fan control is very wrong.

`30-datadog.sh`
-------------------------

Installs DataDog monitoring of mining activities.

| Command-Line Flag            | Required? | Purpose                         |
| ---------------------------- | --------- | ------------------------------- |
| `--datadog-api-key` / `-d`   |           | Your DataDog account's API key. |

If you provide a DataDog API key, this script will install the `dd-agent` and set up monitoring of the various aspects of your mining operation.

### Miner Process ###

* Config: [`/etc/dd-agent/conf.d/systemd-unit.yaml`](datadog/conf.d/systemd-unit.yaml)
* Check: [`/etc/dd-agent/checks.d/systemd-unit.py`](datadog/checks.d/systemd-unit.yaml)

This can actually monitor _any_ systemd process!
By default, it monitors the miner that would be installed by the miner-installation script.

You can add any `systemd` units as an "instance" to monitor that one, too:

`/etc/dd-agent/conf.d/systemd-unit.yaml`
```yaml
init_config:

instances:
 - name: miner-zec-ewbf
 - name: some-other-critical-service
```

### NVidia GPU Metrics ###

* Config: [`/etc/dd-agent/conf.d/nvidia-gpu.yaml`](datadog/conf.d/nvidia-gpu.yaml)
* Check: [`/etc/dd-agent/checks.d/nvidia-gpu.py`](datadog/checks.d/nvidia-gpu.py)

This uses the [`nvidia-smi`](https://developer.nvidia.com/nvidia-system-management-interface) tool to query the GPUs.

#### `gpu_metric_names`

A comma-separated list of metrics to query is provided in the YAML file.
These are provided directly to the `--query-gpu` flag of `nvidia-smi`.
A reasonable list is provided by default.
Any metric that can be returned by `--query-gpu` can be added.

Metrics are reported to DataDog with the same name as used in the configuration file, and _tagged_ with the GPU index.

If the only thing you cared about was GPU temperature, you could reduce the provided YAML to

```yaml
init_config:
 gpu_metric_names: "temperature.gpu"

instances:
 [{}]
```

### Hashrate ###

* Config: [`/etc/dd-agent/conf.d/ewbf-hashrate.yaml`](datadog/conf.d/ewbf-hashrate.yaml)
* Check: [`/etc/dd-agent/checks.d/ewbf-hashrate.py`](datadog/checks.d/ewbf-hashrate.py)

Reads the `systemctl` journal with `journalctl` to see the EWBF miner's log output, and finds the parts where it reported per-GPU solutions-per-second metrics.

#### `ewbf_gpu_hashrate_regex`

In case the EWBF log format changes, the regular expression used to find the per-GPU metrics is configurable.
The first capture group should be the GPU index, and the second capture group should be the metric.

#### `max_log_line_age_minutes`

`journaltcl` buffers output occasionally.
DataDog only checks occasionaly.

This check will read the latest entries in the journal for the miner from the bottom-up, until it finds a line that reports per-GPU hashrate.
However, even if mining has stopped, these log lines will still be present.

This setting allows a maximum age to be configured to avoid the situation where mining ended long ago,
but there is still a log line that shows a non-zero hash rate.

Troubleshooting
==============================

Activating NVidia Drivers
-------------------------

A restart may or may not be required after installing NVidia GPU drivers.
If the miner script cannot install the miner and produces error messages, restart the machine and try again.
