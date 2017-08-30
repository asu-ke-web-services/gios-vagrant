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
