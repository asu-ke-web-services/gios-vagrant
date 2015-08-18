#!/bin/bash
main_sources(){
  add_required_sources
}

add_required_sources() {
  apt-add-repository -y ppa:ondrej/php5
  apt-add-repository -y ppa:chris-lea/node.js
}

main_sources