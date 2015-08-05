#!/bin/bash
#
# Creates Vagrant box. Run as root
# Should have packer installed
set -e
SETUP_DIR=${PWD}
if [ -f "$SETUP_DIR/gios.box" ]; then
  echo "GIOS box exists! Do you want to override y/N"
  read -re override_box
else
  override_box="y"
fi

if [ "$override_box" == y ]; then
  cd "$SETUP_DIR"
  packer build -force template.json
fi
cd "$SETUP_DIR"
vagrant destroy
vagrant box remove gios
vagrant box add gios gios.box
vagrant up