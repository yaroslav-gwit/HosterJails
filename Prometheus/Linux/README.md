# Prometheus Installation Script

These set of shell scripts will automatically install and/or update Prometheus on your Linux distro of choice.

## Requirements

Please, make sure these apps are available on your system before executing any of the scripts below:

```
jq
wget
bash
```

## Deploy.sh

`deploy.sh` automatically installs Prometheus on (almost) any Linux distribution running under `systemd`.
Tested on Debian 12, AlmaLinux 9 and AlmaLinux 8.

> **NOTE**  
> deploy.sh only works on x64 systems for now.  
> More architectures might be coming in the future (I just don't have any way of testing those right now).

## Destroy.sh

`destroy.sh` automatically removes Prometheus from your system, including all of the time-series data, configuration files, an so on.
