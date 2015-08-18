#!/bin/bash
set -e
main_git(){
  install_git
}

install_git(){
  apt-get -y update  && \
  apt-get -y install \
  git \
  git-core \
  subversion
}

main_git