#!/bin/bash
#
# Installs VirtualBox, Vagrant, Packer. Run as root
CODENAME=`lsb_release -c | awk -F ":" '{print $2}'|xargs`

main(){
  bootstrap
  install_virtualbox
  install_vagrant
  install_packer
}

bootstrap() {
  apt-cache search linux-headers-$(uname -r)
  apt-get -y update && \
  apt-get -y install \
  linux-headers-$(uname -r) \
  build-essential \
  curl \
  libcurl4-gnutls-dev \
  libexpat1-dev \
  libssl-dev \
  python-software-properties \
  software-properties-common \
  unzip \
  wget
}

install_virtualbox() {
  # Installing Virtual Box 5.1
  which virtualbox >/dev/null
  if [ "$?" -ne "0" ] ; then
    echo "Virtualbox not found..Installing now"

    sh -c 'echo "deb http://download.virtualbox.org/virtualbox/debian '$CODENAME' contrib" >> /etc/apt/sources.list'
    wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -
    apt-get update && apt-get -y install virtualbox-5.1
  else
    echo "Virtualbox found.. not installing"
  fi
}

install_vagrant() {
  # Installing Vagrant. Download only if it doesnt exist
  which vagrant >/dev/null
  if [ "$?" -ne "0" ] ; then
    echo "Vagrant not found..Installing now"
    wget https://releases.hashicorp.com/vagrant/1.9.4/vagrant_1.9.4_x86_64.deb
    dpkg -i vagrant_1.9.4_x86_64.deb
    rm vagrant_1.9.4_x86_64.deb
    vagrant plugin install vagrant-hostsupdater
  else
    echo "Vagrant found.. not installing"
  fi
}

install_packer() {
  #Install packer to use with vagrant
  which packer >/dev/null

  if [ "$?" -ne "0" ] ; then
    echo "Packer not found..Installing now"
    cd ~/
    if [ ! -d packer ]; then
      mkdir packer
    fi
    cd packer
    wget https://releases.hashicorp.com/packer/1.0.0/packer_1.0.0_linux_amd64.zip
    unzip -o packer_1.0.0_linux_amd64.zip
    rm packer_1.0.0_linux_amd64.zip
    export PATH=$PATH:$HOME/packer/
  else
    echo "Packer found not installing"
  fi
}

main
