#!/bin/bash

##
# This script is designed to be run by itself on a server.
#
# It will download all additional dependencies for you.
#
# It must be run as root.
#
# Usage:
#
#    wget https://raw.githubusercontent.com/drupalprojects/hosting_tasks_extra/7.x-3.x/fix_permissions/scripts/standalone-install-fix-permissions-ownership.sh
#    sudo bash standalone-install-fix-permissions-ownership.sh
#
##

HOSTING_TASKS_EXTRA_VERSION=7.x-3.111
SUDOERS_D_PATH=/etc/sudoers.d
SCRIPTS_DESTINATION=/usr/local/bin

if [ $(id -u) != 0 ]; then
  printf "***********************************************\n"
  printf "* Error: You must run this with sudo or root. *\n"
  printf "***********************************************\n"
  exit 1
fi

DIR=$(dirname "$0")
TYPES=(ownership permissions)

for TYPE in ${TYPES[@]}; do
    SCRIPTS=(fix-drupal-platform-${TYPE} fix-drupal-site-${TYPE})
    for SCRIPT in ${SCRIPTS[@]}; do
      echo "Installing $SCRIPT to ${SCRIPTS_DESTINATION}/${SCRIPT}.sh..."
      wget https://raw.githubusercontent.com/drupalprojects/hosting_tasks_extra/${HOSTING_TASKS_EXTRA_VERSION}/fix_${TYPE}/scripts/${SCRIPT}.sh -O - -q > ${SCRIPTS_DESTINATION}/${SCRIPT}.sh
      chown root:root ${SCRIPTS_DESTINATION}/${SCRIPT}.sh
      chmod u+x ${SCRIPTS_DESTINATION}/${SCRIPT}.sh

      echo "Adding sudoers config to ${SUDOERS_D_PATH}/${SCRIPT}"
      echo "aegir ALL=NOPASSWD: ${SCRIPTS_DESTINATION}/${SCRIPT}.sh" > ${SUDOERS_D_PATH}/${SCRIPT}
      chmod 0440 ${SUDOERS_D_PATH}/${SCRIPT}
    done
done
