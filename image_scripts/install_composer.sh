#!/bin/bash
# install Composer
set -e

main_composer() {
  install_composer
}

install_composer() {
  curl -sS https://getcomposer.org/installer | php
  mv -f composer.phar /usr/local/bin/composer
}

main_composer