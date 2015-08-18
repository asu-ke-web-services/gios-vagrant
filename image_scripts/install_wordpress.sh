#!/bin/bash
#
# Setup Wordpress. This runs as root
set -e

DB_NAME=${1-wordpress}
DB_USER=${2-root}
DB_PASS=${3-root}
DB_HOST=${4-localhost}
DB_TABLE=${5-wp_}
WP_SETUP_DIR=${6-/var/www/html}
WP_VERSION=${7-latest}

main_wordpress(){
  install_wp
}

# install wordpress
install_wp() {

  if [ $WP_VERSION == 'latest' ]; then
    local ARCHIVE_NAME='latest'
  else
    local ARCHIVE_NAME="wordpress-$WP_VERSION"
  fi

  if [ ! -d ${WP_SETUP_DIR}/wordpress ]; then
    mkdir -p ${WP_SETUP_DIR}/wordpress
    cd ${WP_SETUP_DIR}/wordpress
    curl -O https://wordpress.org/${ARCHIVE_NAME}.tar.gz
    tar -zxf ${ARCHIVE_NAME}.tar.gz
    mv wordpress/* ./
    cp wp-config-sample.php wp-config.php
    perl -pi -e "s/database_name_here/$DB_NAME/g" wp-config.php
    perl -pi -e "s/username_here/$DB_USER/g" wp-config.php
    perl -pi -e "s/password_here/$DB_PASS/g" wp-config.php
    perl -pi -e "s/wp_/$DB_TABLE/g" wp-config.php
    perl -pi -e "s/localhost/$DB_HOST/g" wp-config.php
    perl -i -pe'
      BEGIN {
        @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
        push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
        sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
      }
      s/replace this with your own random string to serve as nonce/salt()/ge
    ' wp-config.php
    mkdir wp-content/uploads
    chmod 775 wp-content/uploads
    rmdir wordpress
    rm latest.tar.gz
  else
    echo "Not Installing wordpress.. one exists"
  fi
}

main_wordpress