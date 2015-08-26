#!/bin/bash
set -e
MY_SQL_USER=${1-root}
MY_SQL_PASS=${2-root}
APACHE_WEB_PATH=${3-/var/www/}

main_phpmyadmin() {
  install_phpadmin
}

install_phpadmin() {
  debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
  debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
  debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-user string $MY_SQL_USER"
  debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $MY_SQL_PASS"
  debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $MY_SQL_PASS"
  debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $MY_SQL_PASS"

  apt-get -y update  && \
  apt-get -y install phpmyadmin
}

main_phpmyadmin