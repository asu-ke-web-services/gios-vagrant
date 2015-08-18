#!/bin/bash
set -e
xdebug_config_file="/etc/php5/mods-available/xdebug.ini"

main_xdebug() {
  install_xdebug
  configure_xdebug
}

install_xdebug() {
  apt-get -y update && \
  apt-get -y install \
  php5 \
  php5-xdebug
}

configure_xdebug() {
  # xdebug Config
  [ ! -d /var/log/xdebug ] && mkdir -p /var/log/xdebug
  chown www-data:www-data /var/log/xdebug
  cat << EOF | sudo tee -a ${xdebug_config_file}
  xdebug.scream=1
  xdebug.cli_color=1
  xdebug.show_local_vars=1
EOF
}

main_xdebug