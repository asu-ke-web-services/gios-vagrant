#!/bin/bash
#
# Setup the the GIOS Env. Run as root
set -e

SETUP_DIR=${PWD}

apt-get -y update && \
apt-get -y install unzip

mkdir -p "$SETUP_DIR" && \
cd "$SETUP_DIR"

# Installing Virtual Box 4.3
which virtualbox >/dev/null

if [ "$?" -ne "0" ] ; then
  echo "virtualbox not found..Installing now"
  apt-add-repository 'deb http://download.virtualbox.org/virtualbox/debian saucy contrib' -y
  wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -
  apt-get -y install virtualbox-4.3
else
  echo "Virtualbox found.. not installing"
fi

# Installing Vagrant. Download only if it doesnt exist
which vagrant >/dev/null

if [ "$?" -ne "0" ] ; then
  echo "vagrant not found..Installing now"
  wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.4_x86_64.deb
  dpkg -i vagrant_1.7.4_x86_64.deb
  rm vagrant_1.7.4_x86_64.deb
else
  echo "vagrant found.. not installing"
fi

#Install packer to use with vagrant
which packer >/dev/null

if [ "$?" -ne "0" ] ; then
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
  echo "packer found not installing"
fi