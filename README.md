THIS IS NOT READY
=====

NVidia ZCash Miner on Ubuntu
==============================

Scripts to configure an [**Ubuntu**](https://www.ubuntu.com/download) installation to mine [**ZCash**](https://z.cash/) with [**EWBF Miner**](https://github.com/nanopool/ewbf-miner) on an **NVidia** GPU, as part of the [**FlyPool**](http://zcash.flypool.org) mining pool.
Remote monitoring of the miner with [**DataDog**](https://www.datadoghq.com/) is supported if you have a DataDog account.

You've got to provide your own internet-connected Ubuntu installation but these scripts should be able to take care of the rest.

1. [Getting Started](#getting-started)
2. [Advanced Setup](#advanced-setup)
3. [Setup Modules](#setup-modules)
	1. [NVidia Drivers](#00-nvidiash)
	2. [System](#10-rigsh)
	3. [EWBF Miner](#20-minersh)
	4. [DataDog Monitoring](#30-datadogsh)
4. [Troubleshooting](#troubleshooting)

TODOs
-------------------------

* [ ] verify scripts on other Ubuntu configurations

Getting Started
==============================

Pre-Requisites
-------------------------

| Ubuntu Version | Tested? | Works? |
| -------------- | ------- | ------ |
| Desktop 17.10  |         |        |
| Desktop 16.04  |         |        |
| Server 17.10   | ✔       | ✔      |
| Server 16.04   |         |        |

1. A working, contemporary Ubuntu installation (see chart above).
	1. It is best if this is a _brand new_ installation with no prior configuration and no data to lose!
2. A ZCash t-address
3. A modern NVidia GPU
4. (optional) a DataDog API key for your DataDog account


Installation
-------------------------

1. Clone this repository. You may need to run `sudo apt-get update && apt-get install git` if the installation is brand-new.
2. Run `setup.sh`, providing at least a ZCash t-address:
	```
	./setup.sh --zcash-address tsomethingsomethingsomething
	```
	1. If you have a DataDog account, you can provide your API key to enable monitoring the mining rig:
		```
		./setup.sh \
			--zcash-address tsomethingsomethingsomething \
			--datadog-api-key f00fd00fsomethingsomething
		```
3. When setup completes successfully, run `systemctl start miner-zec-ewbf`.
4. Done!

**Note:** If you change your GPU hardware or the machine's `hostname`, you will need to run these scripts again.

Advanced Setup
==============================

Automatic Login on Ubuntu "Server"
-------------------------

If you have a headless Ubuntu "server" installation and you want the machine to log in and start mining automatically whenever it powers on, run this command:

```
MINER_USER=$(whoami) envsubst < \
	./resources/autologin/etc/systemd/system/getty@tty1.service.d/override.conf.template | \
	sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf \
	>/dev/null
```

* You must not have full-disk encryption enabled.
* You must not have "home directory" encryption enabled.

Setup Modules
==============================

1. [`00-nvidia.sh`](#00-nvidiash)
2. [`10-rig.sh`](#10-rigsh)
3. [`20-miner.sh`](#20-minersh)
4. [`30-datadog.sh`](#30-datadogsh)

Each module is _idempotent_: You can run them multiple times without worry about messing up your system.

`00-nvidia.sh`
-------------------------

Installs NVidia GPU and CUDA drivers.

| Command-Line Flag                | Required? | Purpose                                       |
| -------------------------------- | --------- | --------------------------------------------- |
| `--nvidia-ubuntu-version` / `-v` |           | Identify the NVidia release of Ubuntu Drivers |

### `--nvidia-ubuntu-version`

NVidia drivers for ubuntu are stored at http://developer.download.nvidia.com/compute/cuda/repos.
However, they are not updated for every Ubuntu release.
It may be that the latest NVidia drivers are `1704`, but your Ubuntu installation is something newer, like `17.10`.
In this case, use the `--nvidia-ubuntu-version` flag to provide the correct identifier, e.g. `--nvidia-ubuntu-version 1704`.

The script will instruct you to do this if necessary.

**Note:**

Nvidia driver installation itself is _not_ actully idempotent; the script leaves a breadcrumb in `~/.nvidia-version`
so it can know if the correct drivers have already been installed and skip installing them if they are already present.

`10-rig.sh`
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

**Checks:**

1. [Miner Process](#miner-process)
2. [NVidia GPU Metrics](#nvidia-gpu-metrics)
3. [EWBF Hashrate](#ewbf-hashrate)

### Miner Process ###

* Config: [`/etc/dd-agent/conf.d/systemd-unit.yaml`](resources/datadog/etc/dd-agent/conf.d/systemd-unit.yaml)
* Check: [`/etc/dd-agent/checks.d/systemd-unit.py`](resources/datadog/etc/dd-agent/checks.d/systemd-unit.py)
* Metric: `systemd.<unit name>`

| Configuration Key          | Type          | Purpose                     |
| -------------------------- | ------------- | --------------------------- |
| `unit`                     | `instance`    | The `systemd` unit to check |

This can actually monitor _any_ systemd process!
By default, it monitors the miner that would be installed by the miner-installation script.

You can add any `systemd` units as an "instance" to monitor that one, too:

`/etc/dd-agent/conf.d/systemd-unit.yaml`
```yaml
init_config:

instances:
 - unit: miner-zec-ewbf
 - unit: some-other-critical-service
```

### NVidia GPU Metrics ###

* Config: [`/etc/dd-agent/conf.d/nvidia-gpu.yaml`](resources/datadog/etc/dd-agent/conf.d/nvidia-gpu.yaml)
* Check: [`/etc/dd-agent/checks.d/nvidia-gpu.py`](resources/datadog/etc/dd-agent/checks.d/nvidia-gpu.py)
* Metric: (subset of `nvidia-smi --query-gpu`)

| Configuration Key  | Type          | Purpose                            |
| ------------------ | ------------- | ---------------------------------- |
| `gpu_metric_names` | `init_config` | The `nvidia-smi` metrics to report |


This uses the [`nvidia-smi`](https://developer.nvidia.com/nvidia-system-management-interface) tool to query the GPUs.

#### `gpu_metric_names`

A comma-separated list of metrics to query is provided in the YAML file.
These are provided directly to the `--query-gpu` flag of `nvidia-smi`.
A reasonable list is provided by default.
Any metric that can be returned by `--query-gpu` can be added.

Metrics are reported to DataDog with the same name as used in the configuration file, and _tagged_ with the GPU index.

If the only thing you cared about was GPU temperature, you could reduce the provided YAML to

`/etc/dd-agent/conf.d/nvidia-gpu.yaml`
```yaml
init_config:
 gpu_metric_names: "temperature.gpu"

instances:
 [{}]
```

### Hashrate ###

* Config: [`/etc/dd-agent/conf.d/systemd-unit-hashrate.yaml`](resources/datadog/etc/dd-agent/conf.d/systemd-unit-hashrate.yaml)
* Check: [`/etc/dd-agent/checks.d/systemd-unit-hashrate.py`](resources/datadog/etc/dd-agent/checks.d/systemd-unit-hashrate.py)
* Metric: `gpu.hashrate`

| Configuration Key          | Type          | Purpose                                   |
| -------------------------- | ------------- | ----------------------------------------- |
| `max_log_line_age_minutes` | `init_config` | Prevent stale logs from producing metrics |
| `unit`                     | `instance`    | The `systemd` unit logs to read           |
| `gpu_hashrate_regex`       | `instance`    | Parse hashrate from the `systemd` logs    |

Reads the system journal of a `systemd` unit with `journalctl` to see miner output
and finds the parts where the miner reports per-gpu hash rate.

Multiple instances may be configured to check hash rate from additional `systemd` units, e.g.

`/etc/dd-agent/conf.d/systemd-unit-hashrate.yaml`
```yaml
init_config:
 max_log_line_age_minutes: 5

instances:
 - unit: miner-zec-ewbf
   gpu_hashrate_regex: 'GPU([0-9]+): ([0-9]+) Sol/s'
 - unit: some-other-miner:
   gpu_hashrate_regex: 'gpu #([0-9]+) - ([0-9]+) hashes'
```

#### `max_log_line_age_minutes`

`journaltcl` buffers output occasionally.
DataDog only checks occasionally.

This check will read the latest entries in the journal for the miner from the bottom-up, until it finds a line that reports per-GPU hashrate.
However, even if mining has stopped, these log lines will still be present.

This setting allows a maximum age to be configured to avoid the situation where mining ended long ago,
but there is still a log line that shows a non-zero hash rate.

#### `gpu_hashrate_regex`

The regular expression used to find the per-GPU metrics is configurable.
The first capture group should be the GPU index, and the second capture group should be the metric.

Troubleshooting
==============================

Running off USB
-------------------------
If you run these scripts off of a USB drive, that drive must use a file system that supports POSIX-style permissoins (i.e. can `chmod`).

If your USB drive does not (e.g. if it's formatted with the very-common `fat32` format), you must copy these scripts off of it, first.

Can't Set Fan Speed During Mining
-------------------------

If you provided the `--fan-during-mining <%speed>` flag while installing
but the fans are _not_ actually operating at that speed while mining
(as shown by `nvidia-smi --query-gpu=fan.speed --format=csv`), check
the logs for the miner with `journalctl -u miner-zec-ewbf --lines 100`.

If you see something like this:

	bash[1382]: ERROR: Error assigning value 100 to attribute 'GPUTargetFanSpeed'
	bash[1382]:        (hostname:0[fan:0]) as specified in assignment
	bash[1382]:        '[fan:0]/GPUTargetFanSpeed=100' (Unknown Error).

There can be at least two different causes:

### No Coolbits

If `/etc/X11/xorg.conf` does not contain the "Coolbits" setting, `nvidia-settings` won't allow you to control fans directly.

Run `nvidia-xconfig --cool-bits=4` and then check `/etc/X11/xorg.conf` for a section similar to this:

	Section "Screen"
	    Identifier     "Screen1"
	    Device         "Device1"
	    Monitor        "Monitor1"
	    DefaultDepth    24
	    Option         "Coolbits" "4"
	    Option         "AllowEmptyInitialConfiguration" "True"
	    SubSection     "Display"
	        Depth       24
	    EndSubSection
	EndSection

If it's there, then either you just fixed the issue _or_ that wasn't the issue.
You'll need to restart X before the changes take effect; the simplest way to do that is to reboot.

### Busted Driver Installation

It could be that something's gone wrong with the graphics drivers.
This can happen if you `apt-get install ...` nvidia drivers more than one time.

The only way I know to fix this is to completely remove them, reboot, and reinstall:

	sudo apt-get purge -y nvidia-* cuda* nouveau*
	sudo apt-get autoremove -y
	rm ~/.nvidia-version
	sudo reboot

After that, run the installation scripts again.
