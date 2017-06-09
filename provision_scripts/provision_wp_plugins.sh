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
  # delete the wp plugin folders if they already exist (prevent script from hanging)
  delete_wp_plugins
  install_wp_plugins
  update_wp_plugins
  install_wp_themes
  update_wp_themes
}

delete_wp_plugins(){
  echo "Begin: delete_wp_plugins()"
  for plugin in "${WP_PLUGIN_NAMES[@]}"
  do
    cd ${GIOS_WP_PLUGIN_DIR}
    rm -rf $plugin

    cd ${SOS_WP_PLUGIN_DIR}
    rm -rf $plugin
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
    if [ ! -d "${plugin}" ]; then
      unzip ${PLUGIN_STAGING_DIR}/$plugin
    fi

    cd ${SOS_WP_PLUGIN_DIR}
    if [ ! -d "${plugin}" ]; then
      unzip ${PLUGIN_STAGING_DIR}/$plugin
    fi
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

update_wp_plugins(){
  echo "Begin: update_wp_plugins()"
  cd ${GIOS_WP_PLUGIN_DIR}
  wp plugin update --all --allow-root

  cd ${SOS_WP_PLUGIN_DIR}
  wp plugin update --all --allow-root
}

update_wp_themes(){
  echo "Begin: update_wp_themes()"
  cd ${GIOS_WP_PLUGIN_DIR}
  wp theme update --all --allow-root

  cd ${SOS_WP_PLUGIN_DIR}
  wp theme update --all --allow-root
}

main
