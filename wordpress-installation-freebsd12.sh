#!/usr/local/bin/bash

printf "\n"

## Set the colors ##
NC='\033[0m'
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BROWN_ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'

if [[ $USER = root ]]; then
    printf "You ${GREEN}passed the root user check${NC}, all good.\n"
else
    printf "You are not root!!! Log in as root, please.\n"
    exit
fi

if [[ ${SHELL} = $(which bash) ]] || [[ ${SHELL} = /usr/local/bin/bash ]] || [[ ${SHELL} = /bin/bash ]]; then
	printf "bash is a sane choise of shell, ${GREEN}proceeding with the install${NC}.\n"

else
    printf "This is not bash! Installing and setting bash as your default shell, re-login and start the script again.\n"
    pkg install -y bash &> /dev/null
    chsh -s bash root
    exit
fi

printf "\n"
printf "Installing and configuring software: "

## Install the software required for basic jail stuff ##
pkg update -fq &> /dev/null
pkg upgrade -y &> /dev/null
pkg install -y nano htop bmon iftop pwgen sudo figlet &> /dev/null

printf "."

## Set the correct banner ##
figlet GATEWAY - IT > /etc/motd
service motd restart &> /dev/null

## Up to 12 Oct 2020 the newest version of working MariaDB of FreeBSD was 10.3, that's why it is used here. ##
pkg install -y apache24 mariadb106-server mariadb106-client &> /dev/null

printf "."

## Enable and start the services ##
sysrc apache24_enable=yes mysql_enable=yes &> /dev/null
service apache24 start &> /dev/null
service mysql-server start &> /dev/null

#### Create if check to perform health check on MariaDB server and Apache24 ####
#### Create if check to perform health check on MariaDB server and Apache24 ####

## Generate all of the random values/secrets that are required in the setup ##
#DB_ROOT_PASSWORD=$(makepasswd --minchars 43 --maxchars 51)
#DB_WPDB_NAME=wpdb_$(makepasswd --minchars 3 --maxchars 5 --string=qwertyuiopasdfghjklzxcvbnm)
#DB_WPDB_USER=wpdbuser_$(makepasswd --minchars 4 --maxchars 6 --string=qwertyuiopasdfghjklzxcvbnm)
#DB_WPDB_USER_PASSWORD=$(makepasswd --minchars 43 --maxchars 53)

DB_ROOT_PASSWORD=$(pwgen $(echo $(( $RANDOM % 11 + 51 ))) 1)
DB_WPDB_NAME=wpdb_$(pwgen $(echo $(( $RANDOM % 1 + 3 ))) 1 --no-numerals --no-capitalize)
DB_WPDB_USER=wpdbuser_$(pwgen $(echo $(( $RANDOM % 1 + 3 ))) 1 --no-numerals --no-capitalize)
DB_WPDB_USER_PASSWORD=$(pwgen $(echo $(( $RANDOM % 11 + 51 ))) 1)

## Secure the MariaDB install ##
mysql_secure_installation <<EOF_MSQLSI &> /dev/null

n
y
y
y
y
EOF_MSQLSI

mysql << EOF_SETROOTPASS
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${DB_ROOT_PASSWORD}');
FLUSH PRIVILEGES;
EOF_SETROOTPASS

#### Create check if password lockdown worked, if not, kill the process ####
#### Create check if password lockdown worked, if not, kill the process ####

## Create wordpress database and assign a new user to it ##
mysql -uroot -p${DB_ROOT_PASSWORD} << EOF_WPDATABASE
CREATE DATABASE ${DB_WPDB_NAME};
CREATE USER '${DB_WPDB_USER}'@localhost IDENTIFIED BY '${DB_WPDB_USER_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_WPDB_NAME}.* TO ${DB_WPDB_USER}@'localhost';
FLUSH PRIVILEGES;
EOF_WPDATABASE

printf "."

## Install all of the required PHP stuff ##
pkg install -y mod_php74 php74-mysqli php74-tokenizer php74-zlib php74-zip php74 rsync php74-gd curl php74-curl php74-xml php74-bcmath php74-json php74-mbstring php74-pecl-imagick php74-pecl-imagick-im7 php74-iconv php74-filter php74-pecl-json_post php74-pecl-jsond php74-pear-Services_JSON php74-exif php74-fileinfo php74-openssl php74-dom php74-session php74-ctype php74-simplexml php74-phar php74-gmp &> /dev/null

printf "."

cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

cat <<'EOF_ENABLEPHPFILES' | cat > /usr/local/etc/apache24/Includes/php.conf
<IfModule dir_module>
    DirectoryIndex index.php index.html
    <FilesMatch "\.php$">
        SetHandler application/x-httpd-php
    </FilesMatch>
    <FilesMatch "\.phps$">
        SetHandler application/x-httpd-php-source
    </FilesMatch>
</IfModule>
EOF_ENABLEPHPFILES

printf "."

## Make a selfsigned SSL cert
mkdir -p /usr/local/www/apache24/ssl/

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /usr/local/www/apache24/ssl/self.key -out /usr/local/www/apache24/ssl/self.crt -subj "/C=GB/ST=London/L=London/O=Global Security/OU=Gateway-IT Department/CN=gateway-it.intranet" &> /dev/null

chown www:www /usr/local/www/apache24/ssl/self.key
chown www:www /usr/local/www/apache24/ssl/self.crt

printf ". "

printf "${GREEN}Done${NC}\n"
printf "Downloading WordPress, WP-CLI and populating default config files: "

## Download and install wp-cli ##
cd /root/
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar &> /dev/null
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

printf "."

## Make Apache conf file sensible and ready for use with WordPress
cp /usr/local/etc/apache24/httpd.conf /usr/local/etc/apache24/httpd.conf.BACKUP
rm /usr/local/etc/apache24/httpd.conf

cat <<'EOF_APACHECONFIG' | cat > /usr/local/etc/apache24/httpd.conf
ServerRoot "/usr/local"
Listen 443
LoadModule mpm_prefork_module libexec/apache24/mod_mpm_prefork.so
LoadModule authn_file_module libexec/apache24/mod_authn_file.so
LoadModule authn_core_module libexec/apache24/mod_authn_core.so
LoadModule authz_host_module libexec/apache24/mod_authz_host.so
LoadModule authz_groupfile_module libexec/apache24/mod_authz_groupfile.so
LoadModule authz_user_module libexec/apache24/mod_authz_user.so
LoadModule authz_core_module libexec/apache24/mod_authz_core.so
LoadModule access_compat_module libexec/apache24/mod_access_compat.so
LoadModule auth_basic_module libexec/apache24/mod_auth_basic.so
LoadModule reqtimeout_module libexec/apache24/mod_reqtimeout.so
LoadModule filter_module libexec/apache24/mod_filter.so
LoadModule mime_module libexec/apache24/mod_mime.so
LoadModule log_config_module libexec/apache24/mod_log_config.so
LoadModule env_module libexec/apache24/mod_env.so
LoadModule headers_module libexec/apache24/mod_headers.so
LoadModule setenvif_module libexec/apache24/mod_setenvif.so
LoadModule version_module libexec/apache24/mod_version.so
LoadModule remoteip_module libexec/apache24/mod_remoteip.so
LoadModule ssl_module libexec/apache24/mod_ssl.so
LoadModule unixd_module libexec/apache24/mod_unixd.so
LoadModule status_module libexec/apache24/mod_status.so
LoadModule autoindex_module libexec/apache24/mod_autoindex.so
<IfModule !mpm_prefork_module>
	#LoadModule cgid_module libexec/apache24/mod_cgid.so
</IfModule>
<IfModule mpm_prefork_module>
	#LoadModule cgi_module libexec/apache24/mod_cgi.so
</IfModule>
LoadModule dir_module libexec/apache24/mod_dir.so
LoadModule alias_module libexec/apache24/mod_alias.so
LoadModule rewrite_module libexec/apache24/mod_rewrite.so
LoadModule php7_module        libexec/apache24/libphp7.so

# Third party modules
IncludeOptional etc/apache24/modules.d/[0-9][0-9][0-9]_*.conf
 
<IfModule unixd_module>
User www
Group www
</IfModule>

ServerAdmin random@rdomain.intranet

<Directory />
    AllowOverride None
    Require all denied
</Directory>

SSLEngine on
SSLCertificateFile /usr/local/www/apache24/ssl/self.crt
SSLCertificateKeyFile /usr/local/www/apache24/ssl/self.key

DocumentRoot "/usr/local/www/apache24/data"
<Directory "/usr/local/www/apache24/data">
    Options -Indexes
    AllowOverride All
    Require all granted
</Directory>

<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>

<Files ".ht*">
    Require all denied
</Files>

ErrorLog "/var/log/httpd-error.log"

LogLevel warn

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common

    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>

    CustomLog "/var/log/httpd-access.log" common

</IfModule>

<IfModule alias_module>
    ScriptAlias /cgi-bin/ "/usr/local/www/apache24/cgi-bin/"
</IfModule>

<IfModule cgid_module>
</IfModule>

<Directory "/usr/local/www/apache24/cgi-bin">
    AllowOverride None
    Options None
    Require all granted
</Directory>

<IfModule headers_module>
    RequestHeader unset Proxy early
</IfModule>

<IfModule remoteip_module>
    RemoteIPHeader X-Forwarded-For
    RemoteIPInternalProxy 10.0.0.0/8
    RemoteIPInternalProxy 172.16.0.0/12
    RemoteIPInternalProxy 192.168.0.0/16
</IfModule>

<IfModule mime_module>
    TypesConfig etc/apache24/mime.types
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
</IfModule>

<IfModule proxy_html_module>
Include etc/apache24/extra/proxy-html.conf
</IfModule>

<IfModule ssl_module>
SSLRandomSeed startup builtin
SSLRandomSeed connect builtin
</IfModule>

Include etc/apache24/Includes/*.conf
EOF_APACHECONFIG

## Restart apache and make sure that it's running ##
#### CODE TO DO A HEALTH CHECK IS NOT YET PRESENT ####
service apache24 restart &> /dev/null

printf "."

## Download the latest version of WordPress, move it into the correct folder and assign right permissions ##
cd /tmp

if [[ ! -f /tmp/local.tar.gz ]] ; then
	curl -s https://wordpress.org/latest.tar.gz -o /tmp/local.tar.gz -Y 10000 -y 10
fi

if [[ -f /tmp/local.tar.gz ]] && [[ ! -f local2.tar.gz ]]; then
	sleep 20
	curl -s https://wordpress.org/latest.tar.gz -o /tmp/local2.tar.gz -Y 10000 -y 10

elif [[ ! -f /tmp/local.tar.gz ]] && [[ ! -f local2.tar.gz ]]; then
	sleep 20
	curl -s https://wordpress.org/latest.tar.gz -o /tmp/local.tar.gz -Y 10000 -y 10
	sleep 20
	curl -s https://wordpress.org/latest.tar.gz -o /tmp/local2.tar.gz -Y 10000 -y 10

elif [[ ! -f /tmp/local.tar.gz ]] && [[ ! -f local2.tar.gz ]]; then
    printf "${RED}It seems like you've got problems with the internet connection (or WordPress is limiting your connection rate/download speed). Terminating the installation. Try a bit later.${NC}\n\n"
    exit
fi

while [[ $(ls -al /tmp/ | grep "local.tar.gz" | awk '{print $5}') -ne $(ls -al /tmp/ | grep "local2.tar.gz" | awk '{print $5}') ]]; do
	sleep 20
	if [[ $(ls -al /tmp/ | grep "local.tar.gz" | awk '{print $5}') -ne $(ls -al /tmp/ | grep "local2.tar.gz" | awk '{print $5}') ]]; then
		rm /tmp/local.tar.gz
		curl -s https://wordpress.org/latest.tar.gz -o /tmp/local.tar.gz -Y 10000 -y 10
	fi
	sleep 20
	if [[ $(ls -al /tmp/ | grep "local.tar.gz" | awk '{print $5}') -ne $(ls -al /tmp/ | grep "local2.tar.gz" | awk '{print $5}') ]]; then 
        rm /tmp/local2.tar.gz
	    curl -s https://wordpress.org/latest.tar.gz -o /tmp/local2.tar.gz -Y 10000 -y 10
	fi
	if [[ $(ls -al /tmp/ | grep "local.tar.gz" | awk '{print $5}') -ne $(ls -al /tmp/ | grep "local2.tar.gz" | awk '{print $5}') ]]; then
		printf "${RED}WordPress archive file is broken{$NC}, will retry the download process, until I get it right!\n"
	fi
done

tar xf /tmp/local.tar.gz

printf "."

rm /usr/local/www/apache24/data/index.html

cp -r /tmp/wordpress/* /usr/local/www/apache24/data/
chown -R www:www /usr/local/www/apache24/data/

## .htaccess file + some php.ini configuration settings inside it ##
touch /usr/local/www/apache24/data/.htaccess &> /dev/null
chown www:www /usr/local/www/apache24/data/.htaccess

echo "#PHP.INI VALUES" >> /usr/local/www/apache24/data/.htaccess
echo "php_value upload_max_filesize 500M" >> /usr/local/www/apache24/data/.htaccess
echo "php_value post_max_size 500M" >> /usr/local/www/apache24/data/.htaccess
echo "php_value memory_limit 256M" >> /usr/local/www/apache24/data/.htaccess
echo "php_value max_execution_time 300" >> /usr/local/www/apache24/data/.htaccess
echo "php_value max_input_time 300" >> /usr/local/www/apache24/data/.htaccess

printf "."

## Create a proper WP_CONFIG.PHP, populate it with required DB info and randomize the required values ##
WP_DB_PREFIX=$(pwgen $(echo $(( $RANDOM % 1 + 3 ))) 1 --no-numerals --no-capitalize)
WP_SALT1=$(pwgen 55 1 --secure)
WP_SALT2=$(pwgen 55 1 --secure)
WP_SALT3=$(pwgen 55 1 --secure)
WP_SALT4=$(pwgen 55 1 --secure)
WP_SALT5=$(pwgen 55 1 --secure)
WP_SALT6=$(pwgen 55 1 --secure)
WP_SALT7=$(pwgen 55 1 --secure)
WP_SALT8=$(pwgen 55 1 --secure)

#WP_SALT1=$(makepasswd --chars 55 --string=qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM{}*%^@[])
#WP_SALT2=$(makepasswd --chars 55 --string=qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM{}*%^@[])
#WP_SALT3=$(makepasswd --chars 55 --string=qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM{}*%^@[])
#WP_SALT4=$(makepasswd --chars 55 --string=qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM{}*%^@[])
#WP_SALT5=$(makepasswd --chars 55 --string=qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM{}*%^@[])
#WP_SALT6=$(makepasswd --chars 55 --string=qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM{}*%^@[])
#WP_SALT7=$(makepasswd --chars 55 --string=qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM{}*%^@[])
#WP_SALT8=$(makepasswd --chars 55 --string=qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM{}*%^@[])

cat << 'EOF_WPCONFIG' | cat > /usr/local/www/apache24/data/wp-config.php
<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'database_name_here' );

/** MySQL database username */
define( 'DB_USER', 'username_here' );

/** MySQL database password */
define( 'DB_PASSWORD', 'password_here' );

/** MySQL hostname */
define( 'DB_HOST', 'localhost' );

/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
define( 'NONCE_KEY',        'put your unique phrase here' );
define( 'AUTH_SALT',        'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
define( 'NONCE_SALT',       'put your unique phrase here' );

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
// define('DISABLE_WP_CRON', true);
define('WP_DEBUG', false);

define('WP_SITEURL', 'https://'.$_SERVER['HTTP_HOST']);
define('WP_HOME', 'https://'.$_SERVER['HTTP_HOST']);
define('FORCE_SSL_ADMIN', true);

if (strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false)
$_SERVER['HTTPS']='on';

// If we're behind a proxy server and using HTTPS, we need to alert WordPress of that fact
// see also http://codex.wordpress.org/Administration_Over_SSL#Using_a_Reverse_Proxy
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
	$_SERVER['HTTPS'] = 'on';
}

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

/** Sets up WordPress vars and included files. */
require_once( ABSPATH . 'wp-settings.php' );

EOF_WPCONFIG

sed -i '' "/'AUTH_KEY'/s/put your unique phrase here/$WP_SALT1/" /usr/local/www/apache24/data/wp-config.php
sed -i '' "/'SECURE_AUTH_KEY'/s/put your unique phrase here/$WP_SALT2/" /usr/local/www/apache24/data/wp-config.php
sed -i '' "/'LOGGED_IN_KEY'/s/put your unique phrase here/$WP_SALT3/" /usr/local/www/apache24/data/wp-config.php
sed -i '' "/'NONCE_KEY'/s/put your unique phrase here/$WP_SALT4/" /usr/local/www/apache24/data/wp-config.php
sed -i '' "/'AUTH_SALT'/s/put your unique phrase here/$WP_SALT5/" /usr/local/www/apache24/data/wp-config.php
sed -i '' "/'SECURE_AUTH_SALT'/s/put your unique phrase here/$WP_SALT6/" /usr/local/www/apache24/data/wp-config.php
sed -i '' "/'LOGGED_IN_SALT'/s/put your unique phrase here/$WP_SALT7/" /usr/local/www/apache24/data/wp-config.php
sed -i '' "/'NONCE_SALT'/s/put your unique phrase here/$WP_SALT8/" /usr/local/www/apache24/data/wp-config.php
sed -i '' "/'DB_NAME'/s/database_name_here/$DB_WPDB_NAME/" /usr/local/www/apache24/data/wp-config.php
sed -i '' "/'DB_USER'/s/username_here/$DB_WPDB_USER/" /usr/local/www/apache24/data/wp-config.php
sed -i '' "/'DB_PASSWORD'/s/password_here/$DB_WPDB_USER_PASSWORD/" /usr/local/www/apache24/data/wp-config.php
sed -i '' "/$table_prefix =/s/'wp_'/'${WP_DB_PREFIX}_'/" /usr/local/www/apache24/data/wp-config.php

printf ". "

printf "${GREEN}Done${NC}\n"
printf "Initializing the WordPress installation and removing the default trash: "

## Initialize new WordPress website with WP-CLI, nuke default stuff ##
#WP_CLI_USERNAME=defadm_$(makepasswd --chars 7 --string=qwertyuiopasdfghjklzxcvbnm)
#WP_CLI_USER_PASSWORD=$(makepasswd --minchars 43 --maxchars 51)
#WP_CLI_USER_EMAIL=$(makepasswd --minchars 3 --maxchars 7 --string=qwertyuiopasdfghjklzxcvbnm)@nonexistentdomain.net

WP_CLI_USERNAME=defadm_$(pwgen $(echo $(( $RANDOM % 2 + 3 ))) 1 --no-capitalize --no-numerals)
WP_CLI_USER_PASSWORD=$(pwgen $(echo $(( $RANDOM % 11 + 51 ))) 1 --secure)
WP_CLI_USER_EMAIL=$(pwgen $(echo $(( $RANDOM % 2 + 3 ))) 1 --no-capitalize --no-numerals)@nonexistentdomain.net

mkdir -p /home/www/.wp-cli
touch /home/www/.wp-cli/config.yml
cat << 'EOF_WPCLIYML' | cat > /home/www/.wp-cli/config.yml
path: /usr/local/www/apache24/data/
apache_modules:
  - mod_rewrite
EOF_WPCLIYML

chown -R www /home/www
pw usermod www -d /home/www
#sed -i '' "/World Wide Web Owner/s/\/nonexistent/\/home\/www/" /etc/master.passwd

sudo -u www wp core install --url=127.0.0.1 --title="GWIT Hosted Wordpress Site" --admin_user=$WP_CLI_USERNAME --admin_password=$WP_CLI_USER_PASSWORD --admin_email=${WP_CLI_USER_EMAIL} &> /dev/null
sudo -u www wp rewrite structure '/%postname%/' --hard &> /dev/null
sudo -u www wp plugin delete akismet hello &> /dev/null
sudo -u www wp site empty --yes &> /dev/null
sudo -u www wp theme delete twentyseventeen twentynineteen twentytwenty &> /dev/null

printf " ..... ${GREEN}Done${NC}\n"

## Note with all credentials for later use ##
printf "Writing down all passwords to ${GREEN}wordpress-creds.txt${NC}: "

echo "## Wordpress Web GUI username and password ##" >> /root/wordpress-creds.txt
echo "WP_GUI_USERNAME" - $WP_CLI_USERNAME >> /root/wordpress-creds.txt
echo "WP_GUI_USER_PASSWORD" - $WP_CLI_USER_PASSWORD >> /root/wordpress-creds.txt
echo   >> /root/wordpress-creds.txt
echo "## Mysql/MariaDB root password ##" >> /root/wordpress-creds.txt
echo "DB_ROOT_PASSWORD" - $DB_ROOT_PASSWORD >> /root/wordpress-creds.txt
echo   >> /root/wordpress-creds.txt
echo "## Wordpress DB name, DB user, DB user's password ##" >> /root/wordpress-creds.txt
echo "DB_WPDB_NAME" - $DB_WPDB_NAME >> /root/wordpress-creds.txt
echo "DB_WPDB_USER" - $DB_WPDB_USER >> /root/wordpress-creds.txt
echo "DB_WPDB_USER_PASSWORD" - $DB_WPDB_USER_PASSWORD >> /root/wordpress-creds.txt

printf " ..... ${GREEN}Done${NC} \n"
printf "\n"

## Restart apache and make sure that it's running ##
#### CODE TO DO A HEALTH CHECK IS NOT YET PRESENT ####
service apache24 restart &> /dev/null

IPADDR=$(ifconfig | grep "192\|10\|172" | awk '{print $2}' | awk '/^192|^10|^172/')

##Choose one option, and just comment out second: top - public cloud install, bottom private cloud install. ##
#### IN THE FUTURE I WILL ADD A FLAG TO CHOOSE THIS BEFORE INSTALL ####
#printf "The installation is now finished. Go to ${CYAN}https://${IPADDR}${NC} or \
#${CYAN}https://$(hostname)${NC} or ${CYAN}https://$(curl -s ifconfig.me)${NC} to configure your new site. \n"

printf "The installation is now finished. In case you forgot, this VM IP is: ${CYAN}${IPADDR}${NC}\n"
printf "Go to ${CYAN}https://${IPADDR}/wp-admin/${NC} if you'd like to configure or test your new WordPress website.\n"

printf "\n"

## Printout username and password: ##
printf "Your admin username: "
printf "${CYAN}$WP_CLI_USERNAME${NC} "
printf "and password: "
printf "${CYAN}$WP_CLI_USER_PASSWORD${NC}\n"

printf "\n"
