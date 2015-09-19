#!/bin/bash
RUBY_VERSION=${1-latest}
main_ruby() {
  version=''

  if [ "$RUBY_VERSION" == 'latest' ]; then
    version='--latest'
  else
    version="$RUBY_VERSION"
  fi
  install_ruby "$version"
}

install_ruby() {
  source /etc/profile.d/rvm.sh
  rvm install ruby "$1"
}
main_ruby