#!/bin/bash
#
# Setup Wordpress. This runs as root
set -e
MY_SQL_USER=${1-root}
MY_SQL_PASS=${2-root}
DB_NAME=${3-wordpress}
DB_USER=${4-root}
DB_PASS=${5-root}
DB_HOST=${6-localhost}
mysql_config_file=/etc/mysql/my.cnf
main_mysql(){
  install_mysql
  mysql_restart
  configure_db
  allow_host_to_connect_mysql
  mysql_restart
}

install_mysql() {
  debconf-set-selections <<< "mysql-server mysql-server/root_password password $MY_SQL_PASS"
  debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MY_SQL_PASS"
  apt-get -y install \
  mysql-client \
  mysql-common \
  mysql-server
}

mysql_restart() {
  service mysql restart
}

configure_db() {
  # parse DB_HOST for port or socket references
  local PARTS=(${DB_HOST//\:/ })
  local DB_HOSTNAME=${PARTS[0]};
  local DB_SOCK_OR_PORT=${PARTS[1]};
  local EXTRA=""

  if ! [ -z $DB_HOSTNAME ] ; then
    if [[ "$DB_SOCK_OR_PORT" =~ ^[0-9]+$ ]] ; then
      EXTRA=" --host=$DB_HOSTNAME --port=$DB_SOCK_OR_PORT --protocol=tcp"
    elif ! [ -z $DB_SOCK_OR_PORT ] ; then
      EXTRA=" --socket=$DB_SOCK_OR_PORT"
    elif ! [ -z $DB_HOSTNAME ] ; then
      EXTRA=" --host=$DB_HOSTNAME --protocol=tcp"
    fi
  fi

  # create database for wordpress by default
  dbsetup="CREATE DATABASE IF NOT EXISTS $DB_NAME;GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@$DB_HOST IDENTIFIED BY '$DB_PASS';FLUSH PRIVILEGES;"
  mysql --user="$DB_USER" --password="$DB_PASS"$EXTRA --force -e "$dbsetup"
  if [ $? != "0" ]; then
    echo "Database creation failed. Aborting."
    exit 1
  fi
}

allow_host_to_connect_mysql() {
  perl -pi -e "s/bind-address/#bind-address/g" ${mysql_config_file}
  dbsetup="GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS' WITH GRANT OPTION;FLUSH PRIVILEGES;"
  mysql --user="$DB_USER" --password="$DB_PASS" --force -e "$dbsetup"
}

main_mysql
