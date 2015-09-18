#!/bin/bash
set -e
main_php() {
  install_php
}

install_php() {
  apt-get -y update && \
  apt-get -y install \
  libssh2-php \
  php5 \
  php5-cli \
  php5-common \
  php5-curl \
  php5-dev \
  php5-gd \
  php5-imagick \
  php5-json \
  php5-mysql \
  php5-readline \
  php5-tidy \
  php-pear
}

main_php