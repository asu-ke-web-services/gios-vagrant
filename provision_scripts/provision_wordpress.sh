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

GIOSAPI_DB_NAME=${7-gios2_development}

GIOS_DB_NAME=${8-wordpressGIOSMS}
GIOS_WEB_NAME=${9-sustainability.asu.edu}
GIOS_WP_SETUP_DIR=${WEB_APP_PATH}/${GIOS_WEB_NAME}
GIOS_WP_PLUGIN_DIR=${WEB_APP_PATH}/${GIOS_WEB_NAME}/wp-content/plugins
GIOS_WP_THEMES_DIR=${WEB_APP_PATH}/${GIOS_WEB_NAME}/wp-content/themes

SOS_DB_NAME=${10-wordpressMS}
SOS_WEB_NAME=${11-wordpressMS}
SOS_WP_SETUP_DIR=${WEB_APP_PATH}/${SOS_WEB_NAME}
SOS_WP_PLUGIN_DIR=${WEB_APP_PATH}/${SOS_WEB_NAME}/wp-content/plugins
SOS_WP_THEMES_DIR=${WEB_APP_PATH}/${SOS_WEB_NAME}/wp-content/themes

GIT_AUTHENTICATION_PREFIX="${GIT_USER_NAME}:${GIT_TOKEN}@"

WEB_APPS=( 'gios2-php' )

main(){
  #install_wp
  unzip_wp_dirs
  install_web_apps
  configure_gios_api
}

configure_dev_localsettings(){
  echo "Begin: configure_dev_localsettings()"
  BOOTSTRAP_DIR="${WEB_APP_PATH}/gios2-php"
  TEST_DEPARTMENT_DRIVE_PATH=$BOOTSTRAP_DIR/dept_drive
  TEST_ATTACHMENT_PATH=https://gios-attachments-storage.s3-us-west-2.amazonaws.com/store/

  local DB1_NAME=$1
  local DB2_NAME=$2

  cp localsettings.default.php localsettings.php
  sed -ie "s/YOUR_DB_NAME_HERE/$DB1_NAME/g" localsettings.php
  sed -ie "s/YOUR_HOSTNAME_HERE/$DB_HOST/g" localsettings.php
  sed -ie "s/YOUR_USERNAME_HERE/$DB_USER/g" localsettings.php
  sed -ie "s/YOUR_PASSWORD_HERE/$DB_PASS/g" localsettings.php
  sed -ie "s/YOUR_WP_DB_NAME_HERE/$DB2_NAME/g" localsettings.php
  sed -ie "s/YOUR_WP_HOSTNAME_HERE/$DB_HOST/g" localsettings.php
  sed -ie "s/YOUR_WP_USERNAME_HERE/$DB_USER/g" localsettings.php
  sed -ie "s/YOUR_WP_PASSWORD_HERE/$DB_PASS/g" localsettings.php
  sed -ie "s/YOUR_PATH_TO_THE_DEPARTMENT_DRIVE/$(echo $TEST_DEPARTMENT_DRIVE_PATH | sed -e 's/[]\/$*.^|[]/\\&/g')/g" localsettings.php
  sed -ie "s/YOUR_PATH_TO_THE_ATTACHMENTS_STORE/$(echo $TEST_ATTACHMENT_PATH | sed -e 's/[]\/$*.^|[]/\\&/g')/g" localsettings.php
}

configure_gios_api(){
  echo "Begin: configure_gios_api()"
  cd "${WEB_APP_PATH}/gios2-php"
  composer install --no-interaction --prefer-source
  composer create-project wp-coding-standards/wpcs:0.11.0 --no-dev -n standards/wpcs
  ./vendor/bin/phpcs -vvv -w --config-set installed_paths '../../../standards/gios/,../../../standards/wpcs/'

  mkdir coverage
  bash ./tests/environment-setup/init-test-db.sh gios2_test root 'root' localhost

  # setup localsettings for test environment
  configure_dev_localsettings gios2_test gios2_test
  mv 'localsettings.php' 'localsettings.test.php'

  # setup localsettings for regular dev work
  configure_dev_localsettings gios2_development wordpressMS
  cp 'localsettings.php' 'localsettings.dev.php'

  cd "${WEB_APP_PATH}"
}

install_repo(){
  echo "Begin: install_repo()"
  local SETUP_DIR=$1
  local REPO_NAME=$2
  local ORG_NAME=${3-gios-asu}
  cd "${SETUP_DIR}"
  if [ ! -d "${SETUP_DIR}"/"${REPO_NAME}" ]; then
    git clone --recursive "https://${GIT_AUTHENTICATION_PREFIX}github.com/${ORG_NAME}/${REPO_NAME}.git"

    #Remove any username password stored as plain text in .git/config
    cd "${REPO_NAME}"
    git config --replace-all remote.origin.url "https://github.com/${ORG_NAME}/${REPO_NAME}.git"
    setup_coding_standards "${SETUP_DIR}"/"${REPO_NAME}"
  fi
}

install_web_apps(){
  echo "Begin: install_web_apps()"
  for webapp in "${WEB_APPS[@]}"
  do
    install_repo ${WEB_APP_PATH} $webapp
  done
}

install_wp() {
  echo "Begin: install_wp()"
  if [ $WP_VERSION == 'latest' ]; then
    local ARCHIVE_NAME='latest'
  else
    local ARCHIVE_NAME="wordpress-$WP_VERSION"
  fi

  # Install wordpress for GIOS single-site
  if [ ! -d ${GIOS_WP_SETUP_DIR} ]; then
    mkdir -p ${GIOS_WP_SETUP_DIR}
    cd ${GIOS_WP_SETUP_DIR}
    curl -O https://wordpress.org/${ARCHIVE_NAME}.tar.gz
    tar -zxf ${ARCHIVE_NAME}.tar.gz
    mv wordpress/* ./
    local EXTRA_PHP=$(cat <<'END_HEREDOC'

  // GIOS2-php path:
  function appendToIncludePath($path)
  {
      ini_set('include_path', ini_get('include_path') . PATH_SEPARATOR . $path . DIRECTORY_SEPARATOR);
  }
  appendToIncludePath( '/var/www/html/gios2-php' );

  define('WP_CACHE', false); //Added by WP-Cache Manager
  define( 'WPCACHEHOME', '/var/www/html/giosMS/wp-content/plugins/wp-super-cache/' ); //Added by WP-Cache Manager

  // Enable WP_DEBUG mode
  define( 'WP_DEBUG', true );

  // Enable Debug logging to the /wp-content/debug.log file
  define( 'WP_DEBUG_LOG', true );

  // Disable on-page display of errors and warnings
  define( 'WP_DEBUG_DISPLAY', false );
  @ini_set( 'display_errors', 0 );

  // Use dev versions of core JS and CSS files (only needed if you are modifying these core files)
  define( 'SCRIPT_DEBUG', true );
  define( 'WP_ALLOW_MULTISITE', false );

  define('MULTISITE', false);
  define('SUBDOMAIN_INSTALL', false);
  define('DOMAIN_CURRENT_SITE', 'sustainability.local.gios.asu.edu');
  define('PATH_CURRENT_SITE', '/');
  define('SITE_ID_CURRENT_SITE', 1);
  define('BLOG_ID_CURRENT_SITE', 1);

END_HEREDOC
)
    awk '/define\('\''WP_DEBUG'\'', false\);/{print extra_php RS;next}1' extra_php="$EXTRA_PHP" wp-config-sample.php > wp-config.php
    perl -pi -e "s/database_name_here/$GIOS_DB_NAME/g" wp-config.php
    perl -pi -e "s/username_here/$DB_USER/g" wp-config.php
    perl -pi -e "s/password_here/$DB_PASS/g" wp-config.php
    perl -pi -e "s/wp_/$DB_TABLE_PREFIX/g" wp-config.php
    perl -pi -e "s/localhost/$DB_HOST/g" wp-config.php
    perl -i -pe'
      BEGIN {
        @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
        push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
        sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
      }
      s/put your unique phrase here/salt()/ge
    ' wp-config.php
    mkdir wp-content/uploads
    chmod 775 wp-content/uploads
    rmdir wordpress
    rm ${ARCHIVE_NAME}.tar.gz
  else
    echo "Not Installing GIOS wordpress.. already exists"
  fi

  # Install wordpress for SOS multi-site
  if [ ! -d ${SOS_WP_SETUP_DIR} ]; then
    mkdir -p ${SOS_WP_SETUP_DIR}
    cd ${SOS_WP_SETUP_DIR}
    curl -O https://wordpress.org/${ARCHIVE_NAME}.tar.gz
    tar -zxf ${ARCHIVE_NAME}.tar.gz
    mv wordpress/* ./
    local EXTRA_PHP=$(cat <<'END_HEREDOC'

  // GIOS2-php path:
  function appendToIncludePath($path)
  {
      ini_set('include_path', ini_get('include_path') . PATH_SEPARATOR . $path . DIRECTORY_SEPARATOR);
  }
  appendToIncludePath( '/var/www/html/gios2-php' );

  define('WP_CACHE', false); //Added by WP-Cache Manager
  define( 'WPCACHEHOME', '/var/www/html/sosMS/wp-content/plugins/wp-super-cache/' ); //Added by WP-Cache Manager

  // Enable WP_DEBUG mode
  define( 'WP_DEBUG', true );

  // Enable Debug logging to the /wp-content/debug.log file
  define( 'WP_DEBUG_LOG', true );

  // Disable on-page display of errors and warnings
  define( 'WP_DEBUG_DISPLAY', false );
  @ini_set( 'display_errors', 0 );

  // Use dev versions of core JS and CSS files (only needed if you are modifying these core files)
  define( 'SCRIPT_DEBUG', true );
  define( 'WP_ALLOW_MULTISITE', false );

  define( 'MULTISITE', false );
  define( 'SUBDOMAIN_INSTALL', false );
  $base = '/';
  define( 'DOMAIN_CURRENT_SITE', 'sos.local.gios.asu.edu' );
  define( 'PATH_CURRENT_SITE', '/' );
  define( 'SITE_ID_CURRENT_SITE', 1 );
  define( 'BLOG_ID_CURRENT_SITE', 1 );

END_HEREDOC
)
    awk '/define\('\''WP_DEBUG'\'', false\);/{print extra_php RS;next}1' extra_php="$EXTRA_PHP" wp-config-sample.php > wp-config.php
    perl -pi -e "s/database_name_here/$SOS_DB_NAME/g" wp-config.php
    perl -pi -e "s/username_here/$DB_USER/g" wp-config.php
    perl -pi -e "s/password_here/$DB_PASS/g" wp-config.php
    perl -pi -e "s/wp_/$DB_TABLE_PREFIX/g" wp-config.php
    perl -pi -e "s/localhost/$DB_HOST/g" wp-config.php
    perl -i -pe'
      BEGIN {
        @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
        push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
        sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
      }
      s/put your unique phrase here/salt()/ge
    ' wp-config.php
    mkdir wp-content/uploads
    chmod 775 wp-content/uploads
    rmdir wordpress
    rm ${ARCHIVE_NAME}.tar.gz
  else
    echo "Not Installing SOS wordpress.. already exists"
  fi
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

unzip_wp_dirs() {
  echo "Begin: unzip_wp_dirs()"
  # Extract tarballs with production versions of both multisites (this is yucky)
  cd ${WEB_APP_PATH}
  # tar xzvf ${WEB_APP_PATH}/staging/webdir/sustainability.asu.edu.tar.gz
  # tar xzvf ${WEB_APP_PATH}/staging/webdir/wordpressMS.tar.gz
  unzip ${WEB_APP_PATH}/staging/webdir/sustainability.asu.edu.zip
  unzip ${WEB_APP_PATH}/staging/webdir/wordpressMS.zip

  sed -i "s/define('WP_CACHE', true);/define('WP_CACHE', false);/g" ${GIOS_WP_SETUP_DIR}/wp-config.php
  sed -i "s/define('DB_USER', 'wordpressGIOSMS');/define('DB_USER', 'root');/g" ${GIOS_WP_SETUP_DIR}/wp-config.php
  sed -i "s/define('DB_PASSWORD', 'RC8yuk4PGOh7atzh');/define('DB_PASSWORD', 'root');/g" ${GIOS_WP_SETUP_DIR}/wp-config.php
  sed -i "s/define('DB_HOST', '172.31.9.41');/define('DB_HOST', 'localhost');/g" ${GIOS_WP_SETUP_DIR}/wp-config.php

  sed -i "s/define('WP_CACHE', true);/define('WP_CACHE', false);/g" ${SOS_WP_SETUP_DIR}/wp-config.php
  sed -i "s/define('DB_USER', 'wordpressMS');/define('DB_USER', 'root');/g" ${SOS_WP_SETUP_DIR}/wp-config.php
  sed -i "s/define('DB_PASSWORD', 'MXtHoTpDO3liYWwB');/define('DB_PASSWORD', 'root');/g" ${SOS_WP_SETUP_DIR}/wp-config.php
  sed -i "s/define('DB_HOST', '172.31.9.41');/define('DB_HOST', 'localhost');/g" ${SOS_WP_SETUP_DIR}/wp-config.php
}

main
