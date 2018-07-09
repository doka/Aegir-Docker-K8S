#!/bin/bash

# variables for Aegir
echo "ÆGIR | -------------------------"
echo 'ÆGIR | Hello! '
echo 'ÆGIR | When the database is ready, we will install Aegir with the following options:'
HOSTNAME=`hostname --fqdn`
AEGIR_MAKEFILE="http://cgit.drupalcode.org/provision/plain/aegir-release.make?h=$AEGIR_VERSION"
AEGIR_HOSTMASTER_ROOT="/var/aegir/hostmaster-$AEGIR_VERSION"
PROVISION_VERSION="$AEGIR_VERSION"
AEGIR_CLIENT_EMAIL="aegir@aegir.local.computer"
AEGIR_CLIENT_NAME="admin"
AEGIR_PROFILE="hostmaster"
AEGIR_WORKING_COPY="0"
echo "ÆGIR | -------------------------"
echo "ÆGIR | Hostname: $HOSTNAME"
echo "ÆGIR | Version: $AEGIR_VERSION"
echo "ÆGIR | Database Host: $AEGIR_DATABASE_SERVER"
echo "ÆGIR | Makefile: $AEGIR_MAKEFILE"
echo "ÆGIR | Profile: $AEGIR_PROFILE"
echo "ÆGIR | Root: $AEGIR_HOSTMASTER_ROOT"
echo "ÆGIR | Client Name: $AEGIR_CLIENT_NAME"
echo "ÆGIR | Client Email: $AEGIR_CLIENT_EMAIL"
echo "ÆGIR | Working Copy: $AEGIR_WORKING_COPY"
echo "ÆGIR | TIP: add environment variable to docker-compose.yml file for override defaults."
echo "ÆGIR | -------------------------"
echo "ÆGIR | Checking Aegir directory..."
ls -lah /var/aegir
echo "ÆGIR | -------------------------"
echo "ÆGIR | Running 'drush cc drush' ... "
drush cc drush
echo 'ÆGIR | Checking drush status...'
drush status

#### Install or upgrade provision
# http://docs.aegirproject.org/en/3.x/install/#43-install-provision
# it checks whether Provision is installed only at /var/aegir/.drush/commands
#    VERSION=7.x-3.143 is broken
echo "ÆGIR | -------------------------"
DRUSH_COMMANDS_DIRECTORY="/var/aegir/.drush/commands"
if [ -d "$DRUSH_COMMANDS_DIRECTORY/provision" ]; then
    OLDVERSION=`cat $DRUSH_COMMANDS_DIRECTORY/provision/provision.info | grep "version="`
    echo "ÆGIR | Upgrading provision from $OLDVERSION to $AEGIR_VERSION."
else
    echo "ÆGIR | Provision Commands not found! Installing version $AEGIR_VERSION."
fi
# TBC: it should overwrite existing directory
drush dl provision-$AEGIR_VERSION --destination=$DRUSH_COMMANDS_DIRECTORY -y
echo "ÆGIR | Provision Commands installed / upgaded."

#### Check apache and database
echo "ÆGIR | -------------------------"
echo "ÆGIR | Starting apache2 now to reduce downtime."
sudo apache2ctl graceful
# sudo apache2ctl configtest

# Returns true once mysql can connect.
while ! mysqladmin ping -h"$AEGIR_DATABASE_SERVER" --silent; do
  sleep 3
  echo "ÆGIR | Waiting for database host '$AEGIR_DATABASE_SERVER' ..."
done
echo "ÆGIR | Database '$AEGIR_DATABASE_SERVER' is active!"

#### Install or upgrade hostmaster
# http://docs.aegirproject.org/en/3.x/install/#44-running-hostmaster-install
# http://docs.aegirproject.org/en/3.x/install/upgrade/#upgrading-the-frontend
echo "ÆGIR | -------------------------"
# echo "ÆGIR | Running: drush cc drush"
# drush cc drush

# Check if @hostmaster is already set and accessible.
drush @hostmaster vget site_name > /dev/null 2>&1
if [ ${PIPESTATUS[0]} == 0 ]; then
  echo "ÆGIR | Hostmaster site found. Checking for upgrade platform..."

  # Only upgrade if site not found in current containers platform.
  if [ ! -d "$AEGIR_HOSTMASTER_ROOT/sites/$HOSTNAME" ]; then
      echo "ÆGIR | Site not found at $AEGIR_HOSTMASTER_ROOT/sites/$HOSTNAME, upgrading!"
      echo "ÆGIR | Clear Hostmaster caches and migrate ... "
      drush @hostmaster cc all
      echo "ÆGIR | Running 'drush @hostmaster hostmaster-migrate $HOSTNAME $AEGIR_HOSTMASTER_ROOT -y'...!"
      drush @hostmaster hostmaster-migrate $HOSTNAME $AEGIR_HOSTMASTER_ROOT -y -v
  else
      echo "ÆGIR | Site found at $AEGIR_HOSTMASTER_ROOT/sites/$HOSTNAME"
      # TBD: check drupal version and upgrade if needed !!!
  fi

# if @hostmaster is not accessible, install it.
else
  echo "ÆGIR | Hostmaster not found. Continuing with install!"

  echo "ÆGIR | -------------------------"
  echo "ÆGIR | Running: drush cc drush"
  drush cc drush

  echo "ÆGIR | -------------------------"
  echo "ÆGIR | Running: drush hostmaster-install"
  set -ex
  drush hostmaster-install -y --strict=0 $HOSTNAME \
    --aegir_db_host=$AEGIR_DATABASE_SERVER \
    --aegir_db_pass=$MYSQL_ROOT_PASSWORD \
    --aegir_db_port=3306 \
    --aegir_db_user=root \
    --aegir_db_grant_all_hosts=1 \
    --aegir_host=$HOSTNAME \
    --client_name=$AEGIR_CLIENT_NAME \
    --client_email=$AEGIR_CLIENT_EMAIL \
    --makefile=$AEGIR_MAKEFILE \
    --profile=$AEGIR_PROFILE \
    --root=$AEGIR_HOSTMASTER_ROOT \
    --working-copy=$AEGIR_WORKING_COPY

  sleep 3

  # Exit on the first failed line.
  set -e
  echo "ÆGIR | Running 'drush cc drush' ... "
  drush cc drush

  # enable modules
  echo "ÆGIR | Enabling hosting queued..."
  drush @hostmaster en hosting_queued -y

  echo "ÆGIR | Enabling hosting modules for CiviCRM ..."
  # fix_permissions, fix_ownership, hosting_civicrm, hosting_civicrm_cron
  drush @hostmaster en hosting_civicrm_cron -y
fi

# clean caches
echo "ÆGIR | Clear all caches ... "
drush cc drush
drush @hostmaster cc all

# prepare platform from makefiles
echo "ÆGIR | Deploy platforms in Aegir from makefiles... "
cd /srv/aegir/makefiles
for MAKEFILE in *; do
  PLATFORM=${MAKEFILE%%.make.yml} # strips directory name from filename
  echo "ÆGIR | Platform is: $PLATFORM"
  if [ -d "/var/aegir/platforms/$PLATFORM" ]; then
    # platform exists, do nothing
    echo "ÆGIR | Platform /var/aegir/platforms/$PLATFORM exists, won't overwrite."
  else
    drush make $MAKEFILE /var/aegir/platforms/$PLATFORM
    echo "ÆGIR | New platform $PLATFORM prepared."
  fi
done

# Run whatever is the Docker CMD, typically drush @hostmaster hosting-queued
echo "ÆGIR | Running Docker Command '$@' ..."
exec "$@"
