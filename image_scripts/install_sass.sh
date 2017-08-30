#!/bin/bash
RUBY_VERSION=${1-2.4.1}
set -e
main_sass() {
  install_sass
}

# sass depenencies
install_sass() {
source /etc/profile.d/rvm.sh
rvm use "$RUBY_VERSION"
gem install sass scss_lint
npm install -g grunt grunt-cli
}

main_sass
