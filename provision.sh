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
set -x
. /etc/profile.d/config

DB_NAME=${1-wordpress}
DB_USER=${2-root}
DB_PASS=${3-root}
DB_HOST=${4-localhost}
DB_TABLE_PREFIX=${5-wp_}
WEB_APP_PATH=${6-/var/www/html}
WP_VERSION=${7-4.2.4}

WP_SETUP_DIR=${WEB_APP_PATH}/wordpress
WP_PLUGIN_DIR=${WEB_APP_PATH}/wordpress/wp-content/plugins
WP_THEMES_DIR=${WEB_APP_PATH}/wordpress/wp-content/themes
GIT_AUTHENTICATION_PREFIX="${GIT_USER_NAME}:${GIT_PASSWORD}@"

INSTALL_WP_PLUGINS=( 'wordpress-news-kiosk-plugin' 'gios2-wp' 'wp-front-end-editor' 'wordpress-newsletter-plugin' )
INSTALL_WP_THEMES=( 'ASU-Web-Standards-Wordpress-Theme' )
WEB_APPS=( 'gios2-php' )

main(){
  install_wp_cli
  install_wp
  install_web_apps
  install_wp_plugins
  install_wp_themes
  configure_phpmyadmin
  update_php_ini
  restart_services
}

install_web_apps(){
  for webapp in "${WEB_APPS[@]}"
  do
    install_repo ${WEB_APP_PATH} $webapp
  done
}

install_wp_plugins(){
  for plugin in "${INSTALL_WP_PLUGINS[@]}"
  do
    install_repo ${WP_PLUGIN_DIR} $plugin
  done
}

install_wp_themes(){
  for theme in "${INSTALL_WP_THEMES[@]}"
  do
    install_repo ${WP_THEMES_DIR} $theme
  done
}

setup_coding_standards(){
  local CODING_STANDARDS_DIR=${1}/.standards
  if [ -d "${CODING_STANDARDS_DIR}" ]; then
    cd "${CODING_STANDARDS_DIR}"
    npm install -g grunt grunt-cli
    npm install
    composer install
    ./vendor/bin/phpcs -vvv -w --config-set installed_paths "../../../coding_standards/"
  fi
}

install_repo(){
  local SETUP_DIR=$1
  local REPO_NAME=$2
  local ORG_NAME=${3-gios-asu}
  cd "${SETUP_DIR}"
  if [ ! -d "${SETUP_DIR}"/"${REPO_NAME}" ]; then
    git clone --recursive https://"${GIT_AUTHENTICATION_PREFIX}"github.com/"${ORG_NAME}"/"${REPO_NAME}".git

    #Remove any username password stored as plain text in .git/config
    cd "${REPO_NAME}"
    git config --replace-all remote.origin.url https://github.com/"${ORG_NAME}"/"${REPO_NAME}".git
    setup_coding_standards "${SETUP_DIR}"/"${REPO_NAME}"
  fi
}

install_wp_cli() {
  if [ ! -f /usr/local/bin/wp ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
  fi
}
# install wordpress
install_wp() {

  if [ $WP_VERSION == 'latest' ]; then
    local ARCHIVE_NAME='latest'
  else
    local ARCHIVE_NAME="wordpress-$WP_VERSION"
  fi

  if [ ! -d ${WP_SETUP_DIR} ]; then
    mkdir -p ${WP_SETUP_DIR}
    cd ${WP_SETUP_DIR}
    curl -O https://wordpress.org/${ARCHIVE_NAME}.tar.gz
    tar -zxf ${ARCHIVE_NAME}.tar.gz
    mv wordpress/* ./
    local EXTRA_PHP=$(cat <<'END_HEREDOC'

      if( isset( $_SERVER['HTTPS'] ) ) {
        $protocol='https://';
      } else {
        $protocol='http://';
      }

      if ( isset( $_SERVER['HTTP_HOST'] ) ) {
        define( 'WP_HOME', $protocol . $_SERVER['HTTP_HOST'] . '/wordpress' );
        define( 'WP_SITEURL', $protocol . $_SERVER['HTTP_HOST'] . '/wordpress' );
      }

      define( 'WP_DEBUG', true );
      define( 'WP_DEBUG_LOG', true );
      define( 'WP_DEBUG_DISPLAY', true );
      define( 'SCRIPT_DEBUG', true ) ;

END_HEREDOC
)
    awk '/define\('\''WP_DEBUG'\'', false\);/{print extra_php RS;next}1' extra_php="$EXTRA_PHP" wp-config-sample.php > wp-config.php
    perl -pi -e "s/database_name_here/$DB_NAME/g" wp-config.php
    perl -pi -e "s/username_here/$DB_USER/g" wp-config.php
    perl -pi -e "s/password_here/$DB_PASS/g" wp-config.php
    perl -pi -e "s/wp_/$DB_TABLE_PREFIX/g" wp-config.php
    perl -pi -e "s/localhost/$DB_HOST/g" wp-config.php
    perl -i -pe'
      BEGIN {
        @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
        push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
        sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
      }
      s/put your unique phrase here/salt()/ge
    ' wp-config.php

PHP
    mkdir wp-content/uploads
    chmod 775 wp-content/uploads
    rmdir wordpress
    rm ${ARCHIVE_NAME}.tar.gz
  else
    echo "Not Installing wordpress.. one exists"
  fi
}

configure_phpmyadmin() {
  ln -sf /usr/share/phpmyadmin "${WEB_APP_PATH}"
}

update_php_ini() {
  sed -i "s#;include_path = \".:/usr/share/php\"#include_path = \"/usr/share/php:/var/www/html/gios2-php:.\"#" /etc/php5/apache2/php.ini
  sed -i "s#;include_path = \".:/usr/share/php\"#include_path = \"/usr/share/php:/var/www/html/gios2-php:.\"#" /etc/php5/cli/php.ini
}

restart_services() {
  service apache2 restart
}
main