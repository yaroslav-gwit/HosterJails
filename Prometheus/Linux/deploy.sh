#!/usr/bin/env bash
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root"
    exit 1
fi

# Check if wget is installed
if ! [ -x "$(command -v wget)" ]; then
    echo "Error: wget is not installed. Please install wget and try again."
    exit 2
fi

# Check if jq is installed
if ! [ -x "$(command -v jq)" ]; then
    echo "Error: jq is not installed. Please install jq and try again."
    exit 3
fi

# Detect the architecture
ARCHITECTURE=$(uname -m)
ARCH=""
if [ "$ARCHITECTURE" == "x86_64" ]; then
    ARCH="amd64"
else
    echo "Error: This script only supports x86_64 architecture"
    exit 4
fi

# Find the latest version of Prometheus
LATEST_VERSION=$(wget -qO- https://api.github.com/repos/prometheus/prometheus/releases/latest | jq -r '.tag_name')
LATEST_VERSION=${LATEST_VERSION:1} # Remove the 'v' from the version number

# Download Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v${LATEST_VERSION}/prometheus-${LATEST_VERSION}.linux-${ARCH}.tar.gz
tar -xvzf prometheus*.tar.gz
mv prometheus*${ARCH} prometheus # Move the extracted directory to a generic name

# Create Prometheus user and required service directories
useradd --no-create-home --shell /bin/false prometheus
mkdir /etc/prometheus
mkdir /var/lib/prometheus
chown prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /var/lib/prometheus

# Copy Prometheus files to /usr/local/bin and assign permissions
cp prometheus/prometheus /usr/local/bin/
cp prometheus/promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

# Copy consoles and console_libraries to /etc/prometheus
cp -r prometheus/consoles /etc/prometheus
cp -r prometheus/console_libraries /etc/prometheus
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries

# Create Prometheus config file and assign permissions
cat <<'EOF' >/etc/prometheus/prometheus.yml
global:
  scrape_interval: 60s

scrape_configs:
    - job_name: 'prometheus'
        static_configs:
        - targets: ['localhost:9090']
EOF
chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Create Prometheus systemd service file
cat <<'EOF' >/etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus monitoring system and time series database
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple

ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

ExecReload=/usr/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF

# Start Prometheus service
systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus
systemctl status prometheus # Check the status of the Prometheus service before exiting

# Clean up downloaded files
rm -rfv prometheus*.tar.gz
rm -rfv prometheus
