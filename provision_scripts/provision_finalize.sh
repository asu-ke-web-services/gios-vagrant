#!/bin/bash
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

GIOSAPI_DB_NAME=${7-gios2_production}

GIOS_DB_NAME=${8-giosMS}
GIOS_WP_SETUP_DIR=${WEB_APP_PATH}/${GIOS_DB_NAME}
GIOS_WP_PLUGIN_DIR=${WEB_APP_PATH}/${GIOS_DB_NAME}/wp-content/plugins
GIOS_WP_THEMES_DIR=${WEB_APP_PATH}/${GIOS_DB_NAME}/wp-content/themes

SOS_DB_NAME=${9-sosMS}
SOS_WP_SETUP_DIR=${WEB_APP_PATH}/${SOS_DB_NAME}
SOS_WP_PLUGIN_DIR=${WEB_APP_PATH}/${SOS_DB_NAME}/wp-content/plugins
SOS_WP_THEMES_DIR=${WEB_APP_PATH}/${SOS_DB_NAME}/wp-content/themes

GIT_AUTHENTICATION_PREFIX="${GIT_USER_NAME}:${GIT_TOKEN}@"

INSTALL_GIOS_WP_PLUGINS=( 'wordpress-news-kiosk-plugin' 'gios2-wp' 'wp-front-end-editor' 'wordpress-newsletter-plugin')
WP_PLUGIN_NAMES=( 'cas-maestro' 'contact-form' 'disable-author-pages' 'disable-comments' 'ewww-image-optimizer' 'html-editor-syntax-highlighter' 'simple-custom-css' 'wordpress-seo' 'wp-slick-slider-and-image-carousel' )
INSTALL_WP_PLUGINS=( 'cas-maestro.1.1.3.zip' 'contact-form-7.4.7.zip' 'disable-author-pages.0.11.zip' 'disable-comments.zip' 'ewww-image-optimizer.3.3.1.zip' 'html-editor-syntax-highlighter.1.7.2.zip' 'simple-custom-css.zip' 'wordpress-seo.4.7.1.zip' 'wp-slick-slider-and-image-carousel.zip' )
INSTALL_WP_THEMES=( 'ASU-Web-Standards-Wordpress-Theme' )
WEB_APPS=( 'gios2-php' )

DATABASE_SNAPSHOTS=( 'gios2_production.sql.gz' 'wordpressGIOS.sql.gz' 'wordpressSOS.sql.gz' )

main(){
  configure_phpmyadmin
  update_php_ini
  restart_services
}

configure_phpmyadmin() {
  echo "Begin: configure_phpmyadmin()"
  ln -sf /usr/share/phpmyadmin "${WEB_APP_PATH}"
}

restart_services() {
  echo "Begin: restart_services()"
  service apache2 restart
}

update_php_ini() {
  echo "Begin: update_php_ini()"
  sed -i "s#;include_path = \".:/usr/share/php\"#include_path = \".:/usr/share/php:/var/www/html/gios2-php\"#" /etc/php/7.0/apache2/php.ini

  sed -i "s#;include_path = \".:/usr/share/php\"#include_path = \".:/usr/share/php:/var/www/html/gios2-php\"#" /etc/php/7.0/cli/php.ini
}


main
