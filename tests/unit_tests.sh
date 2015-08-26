#!/bin/bash
set -e
APACHE_WEB_PATH=${1-/var/www}
WEB_APP_PATH="${APACHE_WEB_PATH}"/html
WP_DIR="${WEB_APP_PATH}"/wordpress
WP_PLUGIN_DIR="${WP_DIR}"/wp-content/plugins
WP_THEME_DIR="${WP_DIR}"/wp-content/themes

PACKAGES=( php apache2 mysql git grunt nodejs npm composer sass phpunit )
GUEST_PORTS=( 80 443 22 3306 )
HOST_PORTS=( 8000 44300 2222 33060 )
DIRS=( /usr/share/phpmyadmin "${WP_DIR}" "${WEB_APP_PATH}"/gios2-php "${WP_PLUGIN_DIR}"/gios2-wp "${WP_PLUGIN_DIR}"/wordpress-news-kiosk-plugin "${WP_THEME_DIR}"/ASU-Web-Standards-Wordpress-Theme )
SYMLINKS=( "${WEB_APP_PATH}"/phpmyadmin )

main(){
  start_gios_box
  test_vagrant_running_status
  test_packages
  test_symlinks
  test_dirs
  test_ports_on_guest
  test_ports_on_host
  echo "All tests Completed without errors"
}

start_gios_box() {
  vagrant up &>/dev/null
}

test_vagrant_running_status() {
  gios_vagrant_path=$( dirname $( pwd ) )
  status=$( get_vagrant_global_status | grep -c "$gios_vagrant_path" )
  print_msg_if_count_zero "$status" 'Vagrant not running'
}

test_dirs() {
  for i in "${DIRS[@]}"
  do
    run_function_on_vagrant test_dir_exists $i
  done
}

test_symlinks() {
  for i in "${SYMLINKS[@]}"
  do
    run_function_on_vagrant test_symbolic_link_exists $i
  done
}

test_ports_on_guest() {
  for i in "${GUEST_PORTS[@]}"
  do
    status=$( port_listen_status "$i" | grep -c 'LISTEN' )
    print_msg_if_count_zero "$status" "Port $i"
  done
}

test_ports_on_host() {
  for i in "${HOST_PORTS[@]}"
  do
    status=$( netstat -an | grep "$i" | grep -c 'LISTEN' )
    print_msg_if_count_zero "$status" "Port $i"
  done
}

run_command_on_vagrant(){
  vagrant ssh -c "$1" 2> /dev/null
}

run_function_on_vagrant(){
  run_command_on_vagrant "$( typeset -f $1 );$1 $2;"
}

port_listen_status() {
  cmd="netstat -an | grep $1"
  run_command_on_vagrant "$cmd"
}

get_vagrant_global_status() {
  vagrant global-status
}

test_packages() {
  for i in "${PACKAGES[@]}"
  do
    cmd="which $i"
    status=$( run_command_on_vagrant "$cmd" | wc -l )
    print_msg_if_count_zero "$status" "Package $i not found"
  done
}

test_dir_exists() {
  if [ ! -d "$1" ]; then
    echo "${FUNCNAME[ 0 ]} failed: Dir $1 doesn't exists"
    exit 1
  fi
}

test_symbolic_link_exists() {
  if [ ! -L "$1" ]; then
    echo "${FUNCNAME[ 0 ]} failed: symbolic or file $1 doesn't exists"
    exit 1
  fi
}

print_msg_if_count_zero() {
  prefix_msg=${2-''}
  if [ "$1" -eq 0 ]; then
    echo "${FUNCNAME[ 1 ]} failed: $prefix_msg"
    exit 1
  fi
}

main
