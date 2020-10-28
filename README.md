Yet another bash script to automate WordPress installation for FreeBSD.

Currently supported releases of FreeBSD are: 12.1, 12.2.

### This script will automatically install a fresh WordPress onto your FreeBSD Box. Works on Jails, VMs and bare metal installs.
> Apache and MariaDB will listen on the default ports, so if you are binding your Jails/VMs to the same IP as your host, manually edit the config files to fit your environment.

#### First, run these 2 commands to install the required software, and make *bash* a default shell.
<code>pkg update -f && pkg install -y git bash curl</code><br>
<code>chsh -s bash root</code>

#### Then logout for the changes to apply, log back in and run this oneliner. Run the script as root, *sudo* is not supported at the moment.
For FreeBSD 12:<br>
<code>curl -s https://raw.githubusercontent.com/yaroslav-gwit/freebsd-wordpress-autoinstaller/main/wordpress-installation-freebsd12.sh | bash - </code>
