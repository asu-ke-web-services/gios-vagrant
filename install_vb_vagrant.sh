#!/bin/bash
#
# Installs VirtualBox, Vagrant, Packer. Run as root
set -x
$CODENAME=`lsb_release -c | awk -F ":" '{print $2}'|xargs`
main(){
  bootstrap
  install_virtualbox
  install_vagrant
  install_packer
}

bootstrap() {
  apt-get -y update && \
  apt-get -y install python-software-properties unzip
}

install_virtualbox() {
  # Installing Virtual Box 4.3
  which virtualbox >/dev/null
  if [ "$?" -ne "0" ] ; then
    echo "Virtualbox not found..Installing now"

    sh -c 'echo "deb http://download.virtualbox.org/virtualbox/debian $CODENAME contrib" >> /etc/apt/sources.list'
    wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -
    apt-get update && apt-get -y install virtualbox-4.3
  else
    echo "Virtualbox found.. not installing"
  fi
}

install_vagrant() {
  # Installing Vagrant. Download only if it doesnt exist
  which vagrant >/dev/null
  if [ "$?" -ne "0" ] ; then
    echo "Vagrant not found..Installing now"
    wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.4_x86_64.deb
    dpkg -i vagrant_1.7.4_x86_64.deb
    rm vagrant_1.7.4_x86_64.deb
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
    wget https://dl.bintray.com/mitchellh/packer/packer_0.8.2_linux_amd64.zip
    unzip -o packer_0.8.2_linux_amd64.zip
    rm packer_0.8.2_linux_amd64.zip
    export PATH=$PATH:$HOME/packer/
  else
    echo "Packer found not installing"
  fi
}

main