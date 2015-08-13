#!/bin/bash
#
# Setup the the box. This runs as root
set -ex
echo "Provisioning script started"
# You can install anything you need here.
mysqluser="root"
mysqlpass="root"
mysqlhost="localhost"
dbname="wordpress"
dbuser="root"
dbpass="root"
dbtable="wp_"

php_apache_config_file="/etc/php5/apache2/php.ini"
php_cli_config_file="/etc/php5/cli/php.ini"
xdebug_config_file="/etc/php5/mods-available/xdebug.ini"

debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysqlpass"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysqlpass"
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-user string root"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $mysqlpass"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $mysqlpass"
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $mysqlpass"

apt-get -y update && \
apt-get -y install \
build-essential \
curl \
gettext \
git \
git-core \
libcurl4-gnutls-dev \
libexpat1-dev \
libssl-dev \
python-software-properties \
software-properties-common \
tmux \
unzip \
wget \
vim

apt-add-repository -y ppa:ondrej/php5
apt-add-repository -y ppa:chris-lea/node.js

#Most of the packages here are to install ruby properly and ph5 complete extensions
apt-get -y update && \
apt-get -y install \
apache2 \
libapache2-mod-php5 \
mysql-client \
mysql-common \
mysql-server \
nodejs \
php5 \
php5-cli \
php5-common \
php5-curl \
php5-dev \
php5-gd \
php5-imagick \
php5-imap \
php5-intl \
php5-json \
php5-mcrypt \
php5-memcache \
php5-ming \
php5-mysql \
php5-ps \
php5-pspell \
php5-readline \
php5-recode \
php5-sqlite \
php5-tidy \
php5-xdebug \
php5-xmlrpc \
php5-xsl \
php-pear \
phpmyadmin \
postfix \
subversion

# xdebug Config
[ ! -d /var/log/xdebug ] && mkdir -p /var/log/xdebug
chown www-data:www-data /var/log/xdebug
cat << EOF | sudo tee -a ${xdebug_config_file}
xdebug.scream=1
xdebug.cli_color=1
xdebug.show_local_vars=1
EOF

echo "Installing the above packages done"
sudo service mysql restart

a2enmod rewrite
mkdir /etc/apache2/ssl
# use default options for now
openssl req -batch -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt
a2enmod ssl

[ ! -L /var/www/html/phpmyadmin ] && ln -s /usr/share/phpmyadmin /var/www/html/

# Configure PHP
sed -i "s/display_startup_errors = Off/display_startup_errors = On/g" ${php_apache_config_file}
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" ${php_apache_config_file}
sed -i "s/display_errors = .*/display_errors = On/" ${php_apache_config_file}
sed -i "s/html_errors = Off/html_errors = On/g" ${php_apache_config_file}

# setup php-cli options
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" ${php_apache_config_file}
sudo sed -i "s/display_errors = .*/display_errors = On/" ${php_apache_config_file}
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" ${php_apache_config_file}
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" ${php_apache_config_file}

a2ensite default-ssl.conf
service apache2 reload
service apache2 restart
# install PHPUnit
echo "Installing phpunit"
wget https://phar.phpunit.de/phpunit.phar && \
chmod +x phpunit.phar && \
mv -f phpunit.phar /usr/local/bin/phpunit

# sass depenencies
echo "Installing sass"
gem install sass scss-lint

echo "Installing grunt"
npm install -g grunt grunt-cli

echo "Installing composer"
# install PHPUnit
curl -sS https://getcomposer.org/installer | php
mv -f composer.phar /usr/local/bin/composer

echo "Installing wordpress"

if [ -d /var/www/html/wordpress ]; then
  echo "Wordpress already installed do you want to install fresh one?[y/n]"
  read -re override_wp
else
  override_wp="y"
fi

if [ "$override_wp" == y ]; then
  [ ! -d /var/www/html/wordpress ] && mkdir -p /var/www/html/wordpress
  cd /var/www/html/wordpress

  dbsetup="create database $dbname;GRANT ALL PRIVILEGES ON $dbname.* TO $dbuser@$mysqlhost IDENTIFIED BY '$dbpass';FLUSH PRIVILEGES;"
  mysql -u $mysqluser -p$mysqlpass -e "$dbsetup"
  if [ $? != "0" ]; then
    echo "Database creation failed. Aborting."
    exit 1
  fi
  echo "Installing WordPress."
  curl -O https://wordpress.org/latest.tar.gz
  tar -zxf latest.tar.gz
  mv wordpress/* ./
  cp wp-config-sample.php wp-config.php
  perl -pi -e "s/database_name_here/$dbname/g" wp-config.php
  perl -pi -e "s/username_here/$dbuser/g" wp-config.php
  perl -pi -e "s/password_here/$dbpass/g" wp-config.php
  perl -pi -e "s/wp_/$dbtable/g" wp-config.php
  perl -i -pe'
    BEGIN {
      @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
      push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
      sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
    }
    s/replace this with your own random string to serve as nonce/salt()/ge
  ' wp-config.php
  mkdir wp-content/uploads
  chmod 775 wp-content/uploads
  chown -R www-data:www-data /var/www
  rmdir wordpress
  rm latest.tar.gz
fi

echo "Installation is complete."