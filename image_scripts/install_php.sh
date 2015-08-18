#!/bin/bash
set -e
php_apache_config_file="/etc/php5/apache2/php.ini"
php_cli_config_file="/etc/php5/cli/php.ini"

main_php() {
  install_php
  configure_php
}

install_php() {
  apt-get -y update && \
  apt-get -y install \
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
  php-pear
}

configure_php(){
  # Configure php apache
  sed -i "s/display_startup_errors = Off/display_startup_errors = On/g" ${php_apache_config_file}
  sed -i "s/error_reporting = .*/error_reporting = E_ALL/" ${php_apache_config_file}
  sed -i "s/display_errors = .*/display_errors = On/" ${php_apache_config_file}
  sed -i "s/html_errors = Off/html_errors = On/g" ${php_apache_config_file}

  # setup php-cli options
  sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" ${php_cli_config_file}
  sudo sed -i "s/display_errors = .*/display_errors = On/" ${php_cli_config_file}
  sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" ${php_cli_config_file}
  sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" ${php_cli_config_file}
}

main_php