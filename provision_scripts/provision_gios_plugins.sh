#!/bin/bash
. /etc/profile.d/config

DB_USER=${1-root}
DB_PASS=${2-root}
DB_HOST=${3-localhost}
DB_TABLE_PREFIX=${4-wp_}
WEB_APP_PATH=${5-/var/www/html}
WP_VERSION=${6-latest}

STAGING_DIR=${WEB_APP_PATH}/staging
DB_STAGING_DIR=${STAGING_DIR}/dbs
PLUGIN_STAGING_DIR=${STAGING_DIR}/plugins

GIOSAPI_DB_NAME=${7-gios2_production}

GIOS_DB_NAME=${8-giosMS}
GIOS_WP_SETUP_DIR=${WEB_APP_PATH}/${GIOS_DB_NAME}
GIOS_WP_PLUGIN_DIR=${WEB_APP_PATH}/${GIOS_DB_NAME}/wp-content/plugins
GIOS_WP_THEMES_DIR=${WEB_APP_PATH}/${GIOS_DB_NAME}/wp-content/themes

SOS_DB_NAME=${9-sosMS}
SOS_WP_SETUP_DIR=${WEB_APP_PATH}/${SOS_DB_NAME}
SOS_WP_PLUGIN_DIR=${WEB_APP_PATH}/${SOS_DB_NAME}/wp-content/plugins
SOS_WP_THEMES_DIR=${WEB_APP_PATH}/${SOS_DB_NAME}/wp-content/themes

GIT_AUTHENTICATION_PREFIX="${GIT_USER_NAME}:${GIT_TOKEN}@"

INSTALL_GIOS_WP_PLUGINS=( 'wordpress-news-kiosk-plugin' 'gios2-wp' 'wp-front-end-editor' 'wordpress-newsletter-plugin')
WP_PLUGIN_NAMES=( 'cas-maestro' 'contact-form' 'disable-author-pages' 'disable-comments' 'ewww-image-optimizer' 'html-editor-syntax-highlighter' 'simple-custom-css' 'wordpress-seo' 'wp-slick-slider-and-image-carousel' )
INSTALL_WP_PLUGINS=( 'cas-maestro.1.1.3.zip' 'contact-form-7.4.7.zip' 'disable-author-pages.0.11.zip' 'disable-comments.zip' 'ewww-image-optimizer.3.3.1.zip' 'html-editor-syntax-highlighter.1.7.2.zip' 'simple-custom-css.zip' 'wordpress-seo.4.7.1.zip' 'wp-slick-slider-and-image-carousel.zip' )
INSTALL_WP_THEMES=( 'ASU-Web-Standards-Wordpress-Theme' )
WEB_APPS=( 'gios2-php' )

DATABASE_SNAPSHOTS=( 'gios2_production.sql.gz' 'wordpressGIOS.sql.gz' 'wordpressSOS.sql.gz' )

main(){
  install_gios_wp_plugins
  configure_gios_wp_plugin
}

configure_gios_wp_plugin(){
  echo "Begin: configure_gios_wp_plugin()"
  #echo "machine github.com" >> ~/.netrc
  #echo "  login $GITHUB_TOKEN" >> ~/.netrc
  #chmod 600 ~/.netrc

  local GIOS_CODING_STANDARDS="${GIOS_WP_PLUGIN_DIR}/gios2-wp/.standards/"
  local SOS_CODING_STANDARDS="${SOS_WP_PLUGIN_DIR}/gios2-wp/.standards/"

  for website in "${GIOS_CODING_STANDARDS} ${SOS_CODING_STANDARDS}"
  do
    cd $website
    composer install
    ./vendor/bin/phpcs -vvv -w --config-set installed_paths "../../../wordpress-coding-standards/"
    cd ..
    sudo gem update --system
    #sudo gem install sass
    #sudo gem install scss-lint

    cd .standards
    sudo npm install -g grunt grunt-cli
    npm install

    #git clone --depth=50 --branch=develop "https://github.com/gios-asu/gios2-php.git"  gios2-php
    #cd gios2-php
    #composer install
    #cd ..

    cd ..
    #sudo gem update --system
  done

  # prep test environemnt for wp plugin
  sudo mysqladmin drop -f wordpress_test --user="root" --password="root"
  sudo bash bin/install-wp-tests.sh wordpress_test root 'root' localhost 4.0.1

  cd "${WEB_APP_PATH}"
}

install_gios_wp_plugins(){
  echo "Begin: install_gios_wp_plugins()"
  for plugin in "${INSTALL_GIOS_WP_PLUGINS[@]}"
  do
    install_repo ${GIOS_WP_PLUGIN_DIR} $plugin
    install_repo ${SOS_WP_PLUGIN_DIR} $plugin
  done
}

install_repo(){
  echo "Begin: install_repo()"
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

install_wp_plugins(){
  echo "Begin: install_wp_plugins()"
  for plugin in "${INSTALL_WP_PLUGINS[@]}"
  do
    cd ${GIOS_WP_PLUGIN_DIR}
    unzip ${PLUGIN_STAGING_DIR}/$plugin

    cd ${SOS_WP_PLUGIN_DIR}
    unzip ${PLUGIN_STAGING_DIR}/$plugin
  done
}

install_wp_themes(){
  echo "Begin: install_wp_themes()"
  for theme in "${INSTALL_WP_THEMES[@]}"
  do
    install_repo ${GIOS_WP_THEMES_DIR} $theme
    install_repo ${SOS_WP_THEMES_DIR} $theme
  done
}

setup_coding_standards(){
  echo "Begin: setup_coding_standards()"
  # Install coding standards in the GIOS theme
  local CODING_STANDARDS_DIR=${GIOS_WP_THEMES_DIR}/.standards
  if [ -d "${CODING_STANDARDS_DIR}" ]; then
    cd "${CODING_STANDARDS_DIR}"
    npm install
    composer install
    ./vendor/bin/phpcs -vvv -w --config-set installed_paths "../../../coding_standards/"
  fi
}

main
