#!/bin/bash
#
# Setup the the box. This runs as root
set -e
echo "Provisioning script started"
# You can install anything you need here.
mysqluser="root"
mysqlpass="root"
mysqlhost="localhost"
dbname="wordpress"
dbuser="root"
dbpass="root"
dbtable="wp_"

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
libcurl4-gnutls-dev \
libexpat1-dev \
libssl-dev \
python-software-properties \
software-properties-common \
tmux \
unzip \
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
php5-curl \
php5-gd \
php5-imagick \
php5-imap \
php5-intl \
php5-mcrypt \
php5-memcache \
php5-ming \
php5-mysql \
php5-ps \
php5-pspell \
php5-recode \
php5-snmp \
php5-sqlite \
php5-tidy \
php5-xdebug \
php5-xmlrpc \
php5-xsl \
php-pear \
phpmyadmin \
subversion
# xdebug Config
cat << EOF | sudo tee -a /etc/php5/mods-available/xdebug.ini
xdebug.scream=1
xdebug.cli_color=1
xdebug.show_local_vars=1
EOF

echo "Installing the above packages done"
sudo service mysql restart
a2enmod rewrite
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/apache2/php.ini
service apache2 restart

# sass depenencies
echo "Installing sass"
gem install sass scss-lint

echo "Installing grunt"
npm install -g grunt grunt-cli

echo "Installing composer"
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

sudo ln -s /usr/share/phpmyadmin /var/www/html/

echo "Installing wordpress"

if [ -d "/var/www/html" ]; then
  mkdir -p /var/www/html/wordpress
  cd /var/www/html/wordpress
fi

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
rmdir wordpress
rm latest.tar.gz
echo "Installation is complete."
