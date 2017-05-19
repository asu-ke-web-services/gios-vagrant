#!/bin/bash
#
# Setup Apache. This runs as root
set -e

main_apache(){
  install_apache
  configure_apache
  apache_enable_rewrite
  apache_enable_ssl
  apache_reload
  apache_restart
}

install_apache() {
  apt-get -y update && \
  DEBIAN_FRONTEND=noninteractive apt-get -y install \
  apache2
  #libapache2-mod-php7.0
  #libapache2-mod-auth-mysql
}

configure_apache(){
  chown -R www-data:www-data /var/www
}

apache_reload() {
  service apache2 reload
}

apache_restart() {
  service apache2 restart
}

apache_enable_ssl() {
  [ ! -d /etc/apache2/ssl ] && mkdir /etc/apache2/ssl
  # use default options for now
  openssl req -batch -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt
  a2enmod ssl
  a2ensite default-ssl.conf
}

apache_enable_rewrite() {
  a2enmod rewrite
}

main_apache
