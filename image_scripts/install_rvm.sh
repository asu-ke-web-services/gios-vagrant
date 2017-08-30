#!/bin/bash
main_rvm(){
  install_rvm
}

install_rvm() {
  # RVM
  gpg --keyserver hkp://pgp.mit.edu --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
  \curl -sSL https://get.rvm.io | bash -s stable
}
main_rvm
