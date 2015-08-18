#!/bin/bash
set -e
main_phpunit() {
  install_phpunit
}

# install PHPUnit
install_phpunit() {
  wget https://phar.phpunit.de/phpunit.phar && \
  chmod +x phpunit.phar && \
  mv -f phpunit.phar /usr/local/bin/phpunit
}

main_phpunit