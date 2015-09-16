#!/bin/bash
set -e
main_grunt() {
  insall_grunt
}

insall_grunt() {
  npm install -g grunt grunt-cli
}

main_grunt