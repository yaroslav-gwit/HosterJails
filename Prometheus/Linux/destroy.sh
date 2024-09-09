#!/usr/bin/env bash
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root"
    exit 1
fi

# Check if Prometheus is installed
if ! [ -x "$(command -v prometheus)" ]; then
    echo "Error: Prometheus is not installed"
    exit 2
fi

# Stop Prometheus service
systemctl stop prometheus

# Remove Prometheus service directories
rm -rfv /var/lib/prometheus # This will remove all time series data stored by Prometheus
rm -rfv /etc/prometheus     # This will remove all configuration files
rm -rfv /var/log/prometheus # This will remove all log files

# Remove Prometheus systemd service and it's binary files
rm -fv /etc/systemd/system/prometheus.service
rm -fv /usr/local/bin/prometheus
rm -fv /usr/local/bin/promtool

# Remove Prometheus user and group
userdel prometheus
groupdel prometheus || true

# Reload systemd manager configuration
systemctl daemon-reload
