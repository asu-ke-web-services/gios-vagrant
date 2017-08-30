#!/bin/bash
set -e
main_php() {
  install_php
}

install_php() {
  apt-get -y update && \
  apt-get -y install \
  php7.0 \
  libapache2-mod-php7.0 \
  php-cli \
  php-common \
  php-curl \
  php-dev \
  php-gd \
  php-imagick \
  php-json \
  php-mcrypt \
  php-mysql \
  php-readline \
  php-tidy \
  php-pear
}

main_php
