#!/usr/bin/env bash
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root"
    exit 1
fi

# Update the system and install Chrony using DNF
dnf update -y
dnf install -y chrony

# Backup the default Chrony config
cp /etc/chrony.conf /etc/chrony.conf.BACKUP

# Replace the default Chrony config
cat <<'EOF' >/etc/chrony.conf
# Welcome to the chrony configuration file. See chrony.conf(5) for more information about other directives.
#
# About using servers from the NTP Pool Project in general see (LP: #104525). Approved by Ubuntu Technical Board on 2011-02-08.
# See http://www.pool.ntp.org/join.html for more information.
#
# A list of Ubuntu's NTP servers, which we can quickly revert to if there are any issues with the Janet NTP servers.
# pool ntp.ubuntu.com        iburst maxsources 4
# pool 0.ubuntu.pool.ntp.org iburst maxsources 1
# pool 1.ubuntu.pool.ntp.org iburst maxsources 1
# pool 2.ubuntu.pool.ntp.org iburst maxsources 2

# List of Janet NTP servers
# The servers are provided by Janet, the UK's education and research network
# You may want replace these with the closest NTP servers to you
server ntp0.ja.net iburst
server ntp1.ja.net iburst
server ntp2.ja.net iburst
server ntp3.ja.net iburst
server ntp4.ja.net iburst

# This directive specifies the location of the file containing ID/key pairs for NTP authentication.
keyfile /etc/chrony.keys

# This directive specify the file into which chronyd will store the rate information.
driftfile /var/lib/chrony/chrony.drift

# Comment out the following line to turn the logging off.
log tracking measurements statistics

# Log files location.
logdir /var/log/chrony

# Stop bad estimates upsetting machine clock.
maxupdateskew 100.0

# This directive enables kernel synchronization (every 11 minutes) of the
# real-time clock. Note that it can’t be used along with the 'rtcfile' directive.
rtcsync

# Step the system clock instead of slewing it if the adjustment is larger than
# one second, but only in the first three clock updates.
makestep 1.0 3

# Allow other machines on the network to connect to our chrony server
allow all

EOF

# Enable and start the Chrony service
systemctl enable chronyd && systemctl start chronyd
sleep 5
systemctl restart chronyd

# Check the status of the Chrony service
echo
echo
systemctl status chronyd | cat # Use cat to prevent the output from being paged
echo
echo
chronyc sources -v
echo
echo
chronyc tracking

echo
echo
# Echo green text
echo -e "\e[32mChrony has been installed and configured as an NTP server. \e[0m"
