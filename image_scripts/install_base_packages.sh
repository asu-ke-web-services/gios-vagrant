#!/bin/bash
set -e
main_base_packages() {
  install_base_packages
}

install_base_packages() {
  apt-get -y update  && \
  apt-get -y upgrade  && \
  apt-get -y install \
  build-essential \
  curl \
  gettext \
  libcurl4-gnutls-dev \
  libexpat1-dev \
  libssl-dev \
  postfix \
  python-software-properties \
  software-properties-common \
  tmux \
  unzip \
  wget \
  vim
}

main_base_packages