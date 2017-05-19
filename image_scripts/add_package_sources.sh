#!/bin/bash
main_sources(){
  add_required_sources
}

add_required_sources() {
	# Node 6.x
  curl --silent https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -
  echo "deb https://deb.nodesource.com/node_6.x xenial main" | sudo tee /etc/apt/sources.list.d/nodesource.list
	echo "deb-src https://deb.nodesource.com/node_6.x xenial main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list
}

main_sources
