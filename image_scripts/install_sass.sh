#!/bin/bash
set -e
main_sass() {
  insall_sass
}

# sass depenencies
insall_sass() {
gem install sass scss-lint
npm install -g grunt grunt-cli
}

main_sass