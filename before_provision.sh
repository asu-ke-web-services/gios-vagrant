#!/bin/bash
set -e

#These variables are stored in a file in guest machine and the file
# will be deleted after provisioning that way provision script can have user
# defined variables
store_variables(){
  cat /tmp/settings | while read -r line || [[ -n "$line" ]]; do
    echo "export ${line}" >> /etc/profile.d/config
  done
  chmod +x /etc/profile.d/config
}
store_variables