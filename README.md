### This script will automatically install a fresh WordPress onto your FreeBSD Box. Currently only 12.1-RELEASE supported. Works on Jails and bare metal installs.
#### First install this software onto your FreeBSD box (or Jail, it doesn't matter), and make bash a default shell.
<code>pkg update -f && pkg install -y git bash curl && chsh -s $(which bash) root</code>

#### Then logout for the changes to apply, log back in and run this oneliner.
<code>curl https://raw.githubusercontent.com/yaroslav-gwit/freebsd-wordpress-autoinstaller/main/wordpress-installation-freebsd12-1.sh | bash - </code>
