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

GIT_AUTHENTICATION_PREFIX="${GIT_USER_NAME}:${GIT_PASSWORD}@"

INSTALL_GIOS_WP_PLUGINS=( 'wordpress-news-kiosk-plugin' 'gios2-wp' 'wp-front-end-editor' 'wordpress-newsletter-plugin')
INSTALL_WP_PLUGINS=( cas-maestro.1.1.3.zip contact-form-7.4.7.zip disable-author-pages.0.11.zip disable-comments.zip ewww-image-optimizer.3.3.1.zip html-editor-syntax-highlighter.1.7.2.zip html-editor-syntax-highlighter.1.7.2.zip simple-custom-css.zip wordpress-seo.4.7.1.zip wp-slick-slider-and-image-carousel.zip )
INSTALL_WP_THEMES=( 'ASU-Web-Standards-Wordpress-Theme' )
WEB_APPS=( 'gios2-php' )

DATABASE_SNAPSHOTS=( 'gios2_production.sql.gz' 'wordpressGIOSMS.sql.gz' 'wordpressMS.sql.gz' )

main(){
  install_wp_cli
  install_databases
  install_wp
  install_web_apps
  configure_gios_api
  install_gios_wp_plugins
  configure_gios_wp_plugin
  install_wp_plugins
  install_wp_themes
  configure_phpmyadmin
  update_php_ini
  restart_services
}

configure_dev_localsettings(){
  BOOTSTRAP_DIR="${WEB_APP_PATH}/gios2-php"
  TEST_DEPARTMENT_DRIVE_PATH=$BOOTSTRAP_DIR/dept_drive
  TEST_ATTACHMENT_PATH=$BOOTSTRAP_DIR/attachment_drive

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
  sed -ie "s/'WORDPRESS_BLOG_ID', 33/'WORDPRESS_BLOG_ID', 2/g" localsettings.php
}

configure_gios_api(){
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
  configure_dev_localsettings gios2_production giosMS
  cp 'localsettings.php' 'localsettings.dev.php'

  cd "${WEB_APP_PATH}"
}

configure_gios_wp_plugin(){
  #echo "machine github.com" >> ~/.netrc
  #echo "  login $GITHUB_TOKEN" >> ~/.netrc
  #chmod 600 ~/.netrc

  for website in "${GIOS_WP_PLUGIN_DIR}/gios2-wp/.standards/ ${SOS_WP_PLUGIN_DIR}/gios2-wp/.standards/"
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

configure_phpmyadmin() {
  ln -sf /usr/share/phpmyadmin "${WEB_APP_PATH}"
}

install_databases(){
  # parse DB_HOST for port or socket references
  local PARTS=(${DB_HOST//\:/ })
  local DB_HOSTNAME=${PARTS[0]};
  local DB_SOCK_OR_PORT=${PARTS[1]};
  local EXTRA=""

  if ! [ -z $DB_HOSTNAME ] ; then
    if [[ "$DB_SOCK_OR_PORT" =~ ^[0-9]+$ ]] ; then
      EXTRA=" --host=$DB_HOSTNAME --port=$DB_SOCK_OR_PORT --protocol=tcp"
    elif ! [ -z $DB_SOCK_OR_PORT ] ; then
      EXTRA=" --socket=$DB_SOCK_OR_PORT"
    elif ! [ -z $DB_HOSTNAME ] ; then
      EXTRA=" --host=$DB_HOSTNAME --protocol=tcp"
    fi
  fi

  # create database for GIOS API DB
  dbsetup="DROP DATABASE IF EXISTS $GIOSAPI_DB_NAME;CREATE DATABASE $GIOSAPI_DB_NAME;GRANT ALL PRIVILEGES ON $GIOSAPI_DB_NAME.* TO $DB_USER@$DB_HOST IDENTIFIED BY '$DB_PASS';FLUSH PRIVILEGES;"
  mysql --user="$DB_USER" --password="$DB_PASS"$EXTRA --force -e "$dbsetup"
  if [ $? != "0" ]; then
    echo "Database creation failed. Aborting."
    exit 1
  fi

  # create database for GIOS multisite
  dbsetup="DROP DATABASE IF EXISTS $GIOS_DB_NAME;CREATE DATABASE $GIOS_DB_NAME;GRANT ALL PRIVILEGES ON $GIOS_DB_NAME.* TO $DB_USER@$DB_HOST IDENTIFIED BY '$DB_PASS';FLUSH PRIVILEGES;"
  mysql --user="$DB_USER" --password="$DB_PASS"$EXTRA --force -e "$dbsetup"
  if [ $? != "0" ]; then
    echo "Database creation failed. Aborting."
    exit 1
  fi

  # create database for SOS multisite
  dbsetup="DROP DATABASE IF EXISTS $SOS_DB_NAME;CREATE DATABASE $SOS_DB_NAME;GRANT ALL PRIVILEGES ON $SOS_DB_NAME.* TO $DB_USER@$DB_HOST IDENTIFIED BY '$DB_PASS';FLUSH PRIVILEGES;"
  mysql --user="$DB_USER" --password="$DB_PASS"$EXTRA --force -e "$dbsetup"
  if [ $? != "0" ]; then
    echo "Database creation failed. Aborting."
    exit 1
  fi

  # place database snapshots into ${WEB_APP_PATH}/db-staging folder
  # unzip each database snapshot
  for snapshot in "${DATABASE_SNAPSHOTS[@]}"
  do
    gunzip ${DB_STAGING_DIR}/$snapshot
  done

  # import GIOS DB (no pre-processing needed)
  mysql --user="$DB_USER" --password="$DB_PASS" $GIOSAPI_DB_NAME < ${DB_STAGING_DIR}/${GIOSAPI_DB_NAME}.sql

  # pre-process the wordpress db's
  sed -i "s/wordpressGIOSMS/$GIOS_DB_NAME/g" ${DB_STAGING_DIR}/wordpressGIOSMS.sql
  sed -i "s/sustainability.asu.edu/sustainability.local.gios.asu.edu/g" ${DB_STAGING_DIR}/wordpressGIOSMS.sql

  sed -i "s/wordpressMS/$SOS_DB_NAME/g" ${DB_STAGING_DIR}/wordpressMS.sql
  sed -i "s/wp.prod.gios.asu.edu/wp.local.gios.asu.edu/g" ${DB_STAGING_DIR}/wordpressMS.sql
  sed -i "s/schoolofsustainability.asu.edu/sos.wp.local.gios.asu.edu/g" ${DB_STAGING_DIR}/wordpressMS.sql

  # import wordpress dbs
  mysql --user="$DB_USER" --password="$DB_PASS" $GIOS_DB_NAME < ${DB_STAGING_DIR}/wordpressGIOSMS.sql
  mysql --user="$DB_USER" --password="$DB_PASS" $SOS_DB_NAME < ${DB_STAGING_DIR}/wordpressMS.sql
}

install_gios_wp_plugins(){
  for plugin in "${INSTALL_GIOS_WP_PLUGINS[@]}"
  do
    install_repo ${GIOS_WP_PLUGIN_DIR} $plugin
    install_repo ${SOS_WP_PLUGIN_DIR} $plugin
  done
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

install_web_apps(){
  for webapp in "${WEB_APPS[@]}"
  do
    install_repo ${WEB_APP_PATH} $webapp
  done
}

install_wp() {

  if [ $WP_VERSION == 'latest' ]; then
    local ARCHIVE_NAME='latest'
  else
    local ARCHIVE_NAME="wordpress-$WP_VERSION"
  fi

  # Install wordpress for GIOS multi-site
  if [ ! -d ${GIOS_WP_SETUP_DIR} ]; then
    mkdir -p ${GIOS_WP_SETUP_DIR}
    cd ${GIOS_WP_SETUP_DIR}
    curl -O https://wordpress.org/${ARCHIVE_NAME}.tar.gz
    tar -zxf ${ARCHIVE_NAME}.tar.gz
    mv wordpress/* ./
    local EXTRA_PHP=$(cat <<'END_HEREDOC'

 // Enable WP_DEBUG mode
 define( 'WP_DEBUG', true );

 // Enable Debug logging to the /wp-content/debug.log file
 define( 'WP_DEBUG_LOG', true );

 // Disable on-page display of errors and warnings
 define( 'WP_DEBUG_DISPLAY', false );
 @ini_set( 'display_errors', 0 );

 // Use dev versions of core JS and CSS files (only needed if you are modifying these core files)
 define( 'SCRIPT_DEBUG', true );
 define( 'WP_ALLOW_MULTISITE', true );

 define('MULTISITE', true);
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

 // Enable WP_DEBUG mode
 define( 'WP_DEBUG', true );

 // Enable Debug logging to the /wp-content/debug.log file
 define( 'WP_DEBUG_LOG', true );

 // Disable on-page display of errors and warnings
 define( 'WP_DEBUG_DISPLAY', false );
 @ini_set( 'display_errors', 0 );

 // Use dev versions of core JS and CSS files (only needed if you are modifying these core files)
 define( 'SCRIPT_DEBUG', true );
 define( 'WP_ALLOW_MULTISITE', true );

 define( 'MULTISITE', true );
 define( 'SUBDOMAIN_INSTALL', true );
 $base = '/';
 define( 'DOMAIN_CURRENT_SITE', 'wp.local.gios.asu.edu' );
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

install_wp_cli() {
  if [ ! -f /usr/local/bin/wp ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
  fi
}

install_wp_plugins(){
  for plugin in "${INSTALL_WP_PLUGINS[@]}"
  do
    cd ${GIOS_WP_PLUGIN_DIR}
    gunzip ${PLUGIN_STAGING_DIR}/$plugin

    cd ${SOS_WP_PLUGIN_DIR}
    gunzip ${PLUGIN_STAGING_DIR}/$plugin
  done
}

install_wp_themes(){
  for theme in "${INSTALL_WP_THEMES[@]}"
  do
    install_repo ${GIOS_WP_THEMES_DIR} $theme
    install_repo ${SOS_WP_THEMES_DIR} $theme
  done
}

restart_services() {
  service apache2 restart
}

setup_coding_standards(){
  # Install coding standards in the GIOS theme
  local CODING_STANDARDS_DIR=${GIOS_WP_THEMES_DIR}/.standards
  if [ -d "${CODING_STANDARDS_DIR}" ]; then
    cd "${CODING_STANDARDS_DIR}"
    npm install
    composer install
    ./vendor/bin/phpcs -vvv -w --config-set installed_paths "../../../coding_standards/"
  fi
}

update_php_ini() {
  sed -i "s#;include_path = \".:/usr/share/php\"#include_path = \".:/usr/share/php:/var/www/html/gios2-php\"#" /etc/php/7.0/apache2/php.ini

  sed -i "s#;include_path = \".:/usr/share/php\"#include_path = \".:/usr/share/php:/var/www/html/gios2-php\"#" /etc/php/7.0/cli/php.ini
}


main
