#!/bin/bash
#
# Setup Apache. This runs as root
set -e

main_apache(){
  install_apache
  configure_apache
  apache_enable_rewrite
  apache_config_ssl_vhosts
  apache_reload
  apache_restart
}

install_apache() {
  apt-get -y update && \
  DEBIAN_FRONTEND=noninteractive apt-get -y install \
  apache2
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

apache_config_ssl_vhosts() {
  [ ! -d /etc/apache2/ssl ] && mkdir /etc/apache2/ssl
  mv "/home/vagrant/gios-openssl.conf" "/etc/apache2/ssl/"
  mv "/home/vagrant/gios-vhosts.conf" "/etc/apache2/sites-available/"
  chown -R root:root /etc/apache2/

  # generate self-signed certificate for *.local.gios.asu.edu
  openssl req -batch -x509 -nodes -days 3650 -newkey rsa:2048 -config /etc/apache2/ssl/gios-openssl.conf -extensions v3_req -keyout /etc/apache2/ssl/local.gios.asu.edu-selfsigned.key -out /etc/apache2/ssl/local.gios.asu.edu-selfsigned.crt

  a2enmod ssl
  a2enmod proxy
  a2enmod headers
  a2dissite 000-default
  a2ensite gios-vhosts.conf
}

apache_enable_rewrite() {
  a2enmod rewrite
}

main_apache
