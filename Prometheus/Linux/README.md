# Prometheus Installation Script

These set of shell scripts will automatically install, update or remove Prometheus on your Linux distro of choice.

## Requirements

Please, make sure these apps are available on your system before executing any of the scripts below:

```
jq
wget
curl
bash
```

Execute all scripts from under the `root` user.

## Deploy.sh

`deploy.sh` automatically installs Prometheus on (almost) any Linux distribution running under `systemd`.
Tested on Debian 12, AlmaLinux 9 and AlmaLinux 8.

> **NOTE**  
> deploy.sh only works on x64 systems for now.  
> More architectures might be coming in the future (I just don't have any way of testing those right now).

To start this deployment script you'll need to execute the below:

```shell
curl -sSL https://raw.githubusercontent.com/yaroslav-gwit/HosterJails/main/Prometheus/Linux/deploy.sh | bash
```

## Destroy.sh

`destroy.sh` automatically removes Prometheus from your system, including all of the time-series data, configuration files, log files, etc.

To start this rollback script you'll need to execute the below:

```shell
curl -sSL https://raw.githubusercontent.com/yaroslav-gwit/HosterJails/main/Prometheus/Linux/destroy.sh | bash
```

## Additional information

### Config Location

Main config file location:

```
/etc/prometheus/prometheus.yml
```

To reload Prometheus after the config change, simply execute:

```shell
systemctl reload prometheus
```

### Log Location

Main log file location:

```
/var/log/prometheus/prometheus.log
```

Log file is being rotated every 100MB, whilst keeping 3 (old) backups in total.

### TSDB Retention

The TSDB retention is set to 365 days. I feel like it's a sane default for most production deployments out there.

### Remote Write Receiver

Remote write receiver is enabled by default. More information on this feature here:

```link
https://prometheus.io/docs/prometheus/latest/feature_flags/#remote-write-receiver
```
