#!/bin/bash
#
# Setup the the box. This runs as root
# You can install anything you need here.
# The changes you want on the top of existing box will go into this file.
# These changes will be gone when you destroy the vagrant machine
# This provision scripts runs only once during vagrant up.
# If you want to rerun provision scripts you can do vagrant reload --provision
# If you want changes to be permanent and be part of image which you want
# to build add the changes in image_scripts directory.
. /etc/profile.d/config

DB_USER=${1-root}
DB_PASS=${2-root}
DB_HOST=${3-localhost}
DB_TABLE_PREFIX=${4-wp_}
WEB_APP_PATH=${5-/var/www/html}
WP_VERSION=${6-latest}

STAGING_DIR=${WEB_APP_PATH}/staging
DB_STAGING_DIR=${STAGING_DIR}/dbs
PLUGIN_STAGING_DIR=${STAGING_DIR}/plugins

GIOSAPI_DB_NAME=${7-gios2_development}

GIOS_DB_NAME=${8-wordpressGIOSMS}
GIOS_WEB_NAME=${9-sustainability.asu.edu}
GIOS_WP_SETUP_DIR=${WEB_APP_PATH}/${GIOS_WEB_NAME}
GIOS_WP_PLUGIN_DIR=${WEB_APP_PATH}/${GIOS_WEB_NAME}/wp-content/plugins
GIOS_WP_THEMES_DIR=${WEB_APP_PATH}/${GIOS_WEB_NAME}/wp-content/themes

SOS_DB_NAME=${10-wordpressMS}
SOS_WEB_NAME=${11-wordpressMS}
SOS_WP_SETUP_DIR=${WEB_APP_PATH}/${SOS_WEB_NAME}
SOS_WP_PLUGIN_DIR=${WEB_APP_PATH}/${SOS_WEB_NAME}/wp-content/plugins
SOS_WP_THEMES_DIR=${WEB_APP_PATH}/${SOS_WEB_NAME}/wp-content/themes

GIT_AUTHENTICATION_PREFIX="${GIT_USER_NAME}:${GIT_TOKEN}@"

DATABASE_SNAPSHOTS=( 'gios2_production.sql.gz' 'wordpressGIOSMS.sql.gz' 'wordpressMS.sql.gz' )

main(){
  install_wp_cli
  install_databases
}

install_databases(){
  echo "Begin: install_databases()"
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

  # create database for GIOS API DB
  dbsetup="DROP DATABASE IF EXISTS $GIOSAPI_DB_NAME;CREATE DATABASE $GIOSAPI_DB_NAME;GRANT ALL PRIVILEGES ON $GIOSAPI_DB_NAME.* TO $DB_USER@$DB_HOST IDENTIFIED BY '$DB_PASS';FLUSH PRIVILEGES;"
  mysql --user="$DB_USER" --password="$DB_PASS"$EXTRA --force -e "$dbsetup"
  if [ $? != "0" ]; then
    echo "Database creation failed. Aborting."
    exit 1
  fi

  # create database for GIOS multisite
  dbsetup="DROP DATABASE IF EXISTS $GIOS_DB_NAME;CREATE DATABASE $GIOS_DB_NAME;GRANT ALL PRIVILEGES ON $GIOS_DB_NAME.* TO $DB_USER@$DB_HOST IDENTIFIED BY '$DB_PASS';FLUSH PRIVILEGES;"
  mysql --user="$DB_USER" --password="$DB_PASS"$EXTRA --force -e "$dbsetup"
  if [ $? != "0" ]; then
    echo "Database creation failed. Aborting."
    exit 1
  fi

  # create database for SOS multisite
  dbsetup="DROP DATABASE IF EXISTS $SOS_DB_NAME;CREATE DATABASE $SOS_DB_NAME;GRANT ALL PRIVILEGES ON $SOS_DB_NAME.* TO $DB_USER@$DB_HOST IDENTIFIED BY '$DB_PASS';FLUSH PRIVILEGES;"
  mysql --user="$DB_USER" --password="$DB_PASS"$EXTRA --force -e "$dbsetup"
  if [ $? != "0" ]; then
    echo "Database creation failed. Aborting."
    exit 1
  fi

  # place database snapshots into ${WEB_APP_PATH}/db-staging folder
  # unzip each database snapshot
  for snapshot in "${DATABASE_SNAPSHOTS[@]}"
  do
    gunzip ${DB_STAGING_DIR}/$snapshot
  done

  # preprocess GIOS DB (we need to rename the CREATE DATABASE result.)
  sed -ie "s/gios2_production/gios2_development/g" ${DB_STAGING_DIR}/gios2_production.sql

  # import GIOS DB
  mysql --user="$DB_USER" --password="$DB_PASS" $GIOSAPI_DB_NAME < ${DB_STAGING_DIR}/gios2_production.sql

  # pre-process the wordpress databases
  # TODO

  # import wordpress dbs
  mysql --user="$DB_USER" --password="$DB_PASS" $GIOS_DB_NAME < "${DB_STAGING_DIR}/wordpressGIOSMS.sql"
  mysql --user="$DB_USER" --password="$DB_PASS" $SOS_DB_NAME < "${DB_STAGING_DIR}/wordpressMS.sql"
}

install_wp_cli() {
  echo "Begin: install_wp_cli()"
  if [ ! -f /usr/local/bin/wp ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
  fi
}

main
