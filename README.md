Yet another bash script to automate WordPress installation for FreeBSD.

Script was tested on the following FreeBSD releases: 12.1, 12.2. Please let me know if you tried any other release and it worked.

### This script will automatically install a fresh copy of WordPress along with all it's dependencies (PHP7.4/Apache24/MariaDB10.3) onto your FreeBSD Box. Works on Jails, VMs and bare metal installs.
> Apache and MariaDB will listen on the default ports, so if you are binding your Jails/VMs to the same IP as your host, manually edit the config files to fit your environment.

#### First, run this command to install the required software, and make *bash* a default shell.
```
pkg update -f && pkg install -y bash curl && chsh -s bash root
```

#### Then logout for the changes to apply, log back in and run this oneliner. Run the script as root, *sudo* is not supported at the moment.
For FreeBSD 12:<br>
```
curl -s https://raw.githubusercontent.com/yaroslav-gwit/freebsd-wordpress-autoinstaller/main/wordpress-installation-freebsd12.sh | bash -
```

#### Couple of notes:
- All WordPress files are here: <code>/usr/local/www/apache24/data/</code>
- Apache2 config file is here: <code>/usr/local/etc/apache24/httpd.conf</code>
> There is also <code>/usr/local/etc/apache24/httpd.conf.BACKUP</code>, in case you'd like to check the defaults, add more modules, etc.
- To apply any PHP.INI settings, edit <code>/usr/local/www/apache24/data/.htaccess</code> and follow the example there.
- The installation includes WP-CLI. To run a command with WP-CLI, it must start this way:<br>
```
sudo -u www wp --path='/usr/local/www/apache24/data/' THEN_YOUR_OPTIONS_HERE
```
- The installation is designed to be placed behind a HTTPS reverse proxy, like NGINX or HAProxy. REMOTE IP Apache module is installed and configured. WP-CONFIG.PHP is also slightly altered to play nicely with HTTPS reverse proxy.
- Only HTTPS(443) port is active, to encrypt traffic between the proxy and backend.
- All the default WordPress resoruces are removed upon login. You'll get a cleanest WordPress installation you can think of.

> Disclamer: I am not a superhuman-sysadmin, although I am always trying to keep up with the best practices, I could still make a mistake somewhere, because of that Apache2/PHP74/MariaDB10.3 may have some weak points in it's config. Open an issue and I'll fix everything ASAP. Also, if your WordPress installation requires an additional PHP module, kindly let me know, and I'll add it to the list. Thank you.

<br>
<hr>

#### Consider donating to support a quicker release of new content :)
https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=BYZMNVH4QH3L2&source=url
