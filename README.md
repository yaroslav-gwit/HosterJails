Yet another bash script to automate WordPress installation for FreeBSD.

Currently supported releases are:
12.1
12.2

### This script will automatically install a fresh WordPress onto your FreeBSD Box. Works on Jails, VMs and bare metal installs.
> Apache and MariaDB will listen on the default ports, so if you are binding your Jails/VMs to the same IP as your host, manually edit the config files to fit your environment.

#### First install this software onto your FreeBSD box (or Jail, it doesn't matter), and make bash a default shell.
<code>pkg update -f && pkg install -y git bash curl && chsh -s $(which bash) root</code>

#### Then logout for the changes to apply, log back in and run this oneliner.
<code>curl https://raw.githubusercontent.com/yaroslav-gwit/freebsd-wordpress-autoinstaller/main/wordpress-installation-freebsd12-1.sh | bash - </code>
