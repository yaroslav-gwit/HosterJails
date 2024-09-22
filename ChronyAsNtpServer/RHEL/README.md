# Chrony NTP server installation

This auto-deployment script will install and configure Chrony as NTP server.

## Deployment

To deploy Chrony as NTP server on your RHEL machine, execute the command below:

```shell
echo
```

## Rollback

To roll-back to the default configuration, execute these set of commands:

```shell
sudo su -
cp /etc/chrony.conf.BACKUP /etc/chrony.conf
systemctl restart chrony
```
