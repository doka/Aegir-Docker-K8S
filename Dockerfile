#
# Dockerfile to generate Aegir image to host Durpal & CiviCRM sites
#
# Usage:
# 1. decide on base OS image to use, and adapt this file accordingly:
#   Debian 9 based image (default):
#     Debian 9.4 + PHP 7.0 + Apache + utils
#     details in: supported-os/debian-stretch/Dockerfile
FROM wepoca/stretch-php7
#
#   Ubuntu 16.04 LTS based image:
#     Ubuntu 16.04 + PHP 7.0 + Apache + utils
#     details in: supported-os/ubuntu1604lts/Dockerfile
# FROM wepoca/lts-php7
#
# 2. build image
#   docker build -t aegir .
#
# 3. optional: tag & upload, instead "wepoca" use your Docker user
#   docker tag aegir:latest wepoca/aegir
#   docker push wepoca/aegir
#
# 4. use docker-compose.yml to start up volumes & containers to fly :)
#
# ----------------------------------
# Image & package info:
# - PHP 7.0 prepared for Aegir 3.x and CiviCRM
# - Apache, mysql client, Postfix and utils like sudo, nano, git, wget
# - the aegir image installs and upgrades Aegir components
# - the particular Aegir version has to be defined in docker-compose.yml
# - /var/aegir and /var/lib/mysql are persistent volumes
#
# ----------------------------------
# TODO:
# - proper clean-up to minimize image size
# - Fix Ownership and Fix Permissions module setup with CiviCRM
# - Postfix setup
#
ENV DEBIAN_FRONTEND=noninteractive

#### 2 - Set environment variables
# Composer
# Pick up one commit of last composer builds
# https://github.com/composer/getcomposer.org/commits/master
# build used: 1.6.5 from 2018-05-04
ENV COMPOSER_COMMIT fe44bd5b10b89fbe7e7fc70e99e5d1a344a683dd

# Drush 8
# Pick the latest stable Dursh 8 version
# https://github.com/drush-ops/drush/releases
# ENV DRUSH_VERSION 8.1.16
ENV DRUSH_VERSION 8.1.17

# aegir user ID
# TBC There are both ARG and ENV lines to make sure the value persists.
# See https://docs.docker.com/engine/reference/builder/#/arg
ARG AEGIR_UID=1000
ENV AEGIR_UID ${AEGIR_UID:-1000}

#### 3 - Create the Aegir user with sudo rights for Apache
# http://docs.aegirproject.org/en/3.x/install/#31-create-the-aegir-user
# http://docs.aegirproject.org/en/3.x/install/#34-sudo-configuration
RUN echo "Creating user aegir with UID $AEGIR_UID and GID $AEGIR_UID" && \
    addgroup --gid $AEGIR_UID aegir && \
    adduser --uid $AEGIR_UID --gid $AEGIR_UID --system --home /var/aegir aegir && \
    adduser aegir www-data
# sudo for aegir user for apache2ctl
COPY sudoers-aegir /etc/sudoers.d/aegir
RUN chmod 0440 /etc/sudoers.d/aegir

#### 4 - Apache configuration
# http://docs.aegirproject.org/en/3.x/install/#321-apache-configuration
RUN a2enmod rewrite
# RUN a2enmod ssl
# needed for Aegir upgrades
RUN ln -s /var/aegir/config/apache.conf /etc/apache2/conf-available/aegir.conf &&\
    ln -s /etc/apache2/conf-available/aegir.conf /etc/apache2/conf-enabled/aegir.conf
# TBD: RUN a2enconf aegir

#### 5 - PHP configuration
# http://docs.aegirproject.org/en/3.x/install/#33-php-configuration
## PHP memory limit
# memory_limit = 192M in /etc/php/7.0/cli/php.ini
# memory_limit = 192M in /etc/php/7.0/apache2/php.ini
RUN sed -i 's/memory_limit = -1/memory_limit = 192M/' /etc/php/7.0/cli/php.ini && \
    sed -i 's/memory_limit = 128M/memory_limit = 192M/' /etc/php/7.0/apache2/php.ini

#### 6 - Install Composer & Drush
# http://docs.aegirproject.org/en/3.x/install/#41-install-drush
RUN wget https://raw.githubusercontent.com/composer/getcomposer.org/$COMPOSER_COMMIT/web/installer -O - -q | php -- --quiet
RUN cp composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer
# Drush
RUN wget https://github.com/drush-ops/drush/releases/download/$DRUSH_VERSION/drush.phar -O - -q > /usr/local/bin/drush
RUN chmod +x /usr/local/bin/drush

#### 7 - copy Docker entrypoint file to install/upgrade Aegir
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

#### 8 - copy makefiles generating platforms for Aegir
RUN mkdir -p /srv/aegir/makefiles
COPY platform-makefile/*.make.yml /srv/aegir/makefiles/

#### 9 - switch to Aegir user
USER aegir
WORKDIR /var/aegir

#### 10 - docker-entrypoint.sh waits for database and
# runs Aegir install/upgrade as aegir user
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["drush", "@hostmaster", "hosting-queued"]
