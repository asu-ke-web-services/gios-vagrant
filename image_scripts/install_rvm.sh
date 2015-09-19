#!/bin/bash
main_rvm(){
  install_rvm
}

install_rvm() {
  apt-get -y update && \
  apt-get -y install rvm && \
  source /etc/profile.d/rvm.sh
}
main_rvm
