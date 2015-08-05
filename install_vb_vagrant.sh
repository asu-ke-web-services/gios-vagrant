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
apt-add-repository 'deb http://download.virtualbox.org/virtualbox/debian saucy contrib' -y
wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -
apt-get -y install virtualbox-4.3

# Installing Vagrant. Download only if it doesnt exist
if [ ! -f vagrant_1.7.4_x86_64.deb ]; then
  wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.4_x86_64.deb
fi
dpkg -i vagrant_1.7.4_x86_64.deb

#Install packer to use with vagrant
cd ~/
if [ ! -d packer ]; then
  mkdir packer
fi
cd packer
if [ ! -f packer_0.8.2_linux_amd64.zip ]; then
  wget https://dl.bintray.com/mitchellh/packer/packer_0.8.2_linux_amd64.zip
fi
unzip -o packer_0.8.2_linux_amd64.zip
export PATH=$PATH:$HOME/packer/

