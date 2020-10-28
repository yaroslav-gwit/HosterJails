Yet another bash script to automate WordPress installation for FreeBSD.

Currently supported releases of FreeBSD are: 12.1, 12.2.

### This script will automatically install a fresh WordPress onto your FreeBSD Box. Works on Jails, VMs and bare metal installs.
> Apache and MariaDB will listen on the default ports, so if you are binding your Jails/VMs to the same IP as your host, manually edit the config files to fit your environment.

#### First, run this command to install the required software, and make *bash* a default shell.
<code>pkg update -f && pkg install -y bash curl && chsh -s bash root</code>

#### Then logout for the changes to apply, log back in and run this oneliner. Run the script as root, *sudo* is not supported at the moment.
For FreeBSD 12:<br>
<code>curl -s https://raw.githubusercontent.com/yaroslav-gwit/freebsd-wordpress-autoinstaller/main/wordpress-installation-freebsd12.sh | bash - </code>

#### Couple of notes:
- All WordPress files are here: <code>/usr/local/www/apache24/data/</code>
- Apache2 config file is here: <code>/usr/local/etc/apache24/httpd.conf</code>
> There is also <code>/usr/local/etc/apache24/httpd.conf.BACKUP</code>, in case you'd like to check the defaults, add more modules, etc.
- To apply any PHP.INI settings, edit <code>/usr/local/www/apache24/data/.htaccess</code> and follow the example there.
- The installation includes WP-CLI. To run a command with WP-CLI, it must start this way:<br>
<code>sudo -u www wp --path='/usr/local/www/apache24/data/'</code> THEN_YOUR_OPTIONS_HERE
