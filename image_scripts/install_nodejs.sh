#!/bin/bash
set -e
main_nodejs() {
  install_nodejs
}

install_nodejs() {
  apt-get -y update  && \
  apt-get -y install nodejs
}

main_nodejs