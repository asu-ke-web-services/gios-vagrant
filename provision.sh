#!/bin/bash
#
# Setup the the box. This runs as root
# You can install anything you need here.
# The changes you want on the top of existing box will go into this file.
# These changes will be gone when you destroy the vagrant machine
# This provision scripts runs only once during vagrant up.
# If you want to rerun provision scripts you can do vagrant reload --provision
# If you want changes to be permanent and be part of image which you want
# to build add the changes in image_scripts directory.
set -e

. /etc/profile.d/config

WEB_PATH=/var/www/html
WP_PLUGIN_DIR=${WEB_PATH}/wordpress/wp-content/plugins
WP_THEMES_DIR=${WEB_PATH}/wordpress/wp-content/themes
GIT_AUTHENTICATION_PREFIX="${GIT_USER_NAME}:${GIT_PASSWORD}@"
IS_TRAVIS_BUILD="${IS_TRAVIS_BUILD}"
if [ "${IS_TRAVIS_BUILD}" == "YES" ]; then
  GIT_AUTHENTICATION_PREFIX=""
fi
main(){
  install_web_apps
  install_wp_plugins
  install_wp_themes
}

install_web_apps(){
  install_gios2_api
}
install_wp_plugins(){
  install_wordpress_news_kiosk_plugin
  install_gios_wp_plugin
  install_wp_front_end_editor_plugin
  install_wordpress_newsletter_plugin
}

install_wp_themes(){
  install_asu_web_standards_wordpress_theme
}

install_wordpress_news_kiosk_plugin(){
  install_repo ${WP_PLUGIN_DIR} wordpress-news-kiosk-plugin
}

install_gios_wp_plugin(){
  #Do not install private repo on travis as we not have authentication details
  if [ "${IS_TRAVIS_BUILD}" != "YES" ]; then
    install_repo ${WP_PLUGIN_DIR} gios2-wp
  fi
}

install_wp_front_end_editor_plugin(){
  install_repo ${WP_PLUGIN_DIR} wp-front-end-editor
}

install_wordpress_newsletter_plugin(){
  install_repo ${WP_PLUGIN_DIR} wordpress-newsletter-plugin
}

install_gios2_api(){
  #Do not install private repo on travis as we not have authentication details
  if [ "${IS_TRAVIS_BUILD}" != "YES" ]; then
    install_repo ${WEB_PATH} gios2-php
  fi
}

install_asu_web_standards_wordpress_theme(){
  install_repo ${WP_THEMES_DIR} ASU-Web-Standards-Wordpress-Theme
}

setup_coding_standards(){
  local CODING_STANDARDS_DIR=${1}/.standards
  if [ -d "${CODING_STANDARDS_DIR}" ]; then
    cd "${CODING_STANDARDS_DIR}"
    npm install -g grunt grunt-cli
    npm install
  fi
}

install_repo(){
  local SETUP_DIR=$1
  local REPO_NAME=$2
  local ORG_NAME=${3-gios-asu}
  cd "${SETUP_DIR}"
  if [ ! -d "${SETUP_DIR}"/"${REPO_NAME}" ]; then
    git clone --recursive https://"${GIT_AUTHENTICATION_PREFIX}"github.com/"${ORG_NAME}"/"${REPO_NAME}".git

    #Remove any username password stored as plain text in .git/config
    cd "${REPO_NAME}"
    git config --replace-all remote.origin.url https://github.com/"${ORG_NAME}"/"${REPO_NAME}".git
    setup_coding_standards "${SETUP_DIR}"/"${REPO_NAME}"
  fi
}

main