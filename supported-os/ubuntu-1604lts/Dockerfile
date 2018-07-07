#
# Dockerfile to generate Ubuntu 16.04 LTS server for Aegir
# to host Durpal & CiviCRM sites
#
# Usage:
#   cd supported-os/ubuntu-1604lts
#   docker build -t lts .
#   docker tag lts:latest wepoca/lts-php7
#   docker push wepoca/lts-php7
#
# ----------------------------------
# Base image & packages:
# - https://hub.docker.com/_/ubuntu/
# - PHP 7.0 prepared for Aegir 3.x and CiviCRM
# - Apache
# - mysql client
# - Postfix
# - utils like sudo, nano, git, wget
#
# ----------------------------------
# TODO:
# - proper clean-up to minimize image size
# - is the curl package needed?
# - install the PECL uploadprogress library
# - adjust PHP settings
#
# -------------------------------------
# Ubuntu specifics:
# - Ubuntu has no default mysql-client
#
#
FROM ubuntu:16.04
ENV DEBIAN_FRONTEND=noninteractive
#
RUN apt-get update -qq && apt-get install -y -qq \
  apache2 \
  libapache2-mod-php7.0 \
  php7.0-gd \
  php7.0-curl \
  php7.0-xml \
  php7.0-mbstring \
  php7.0-mysql \
  php7.0-mcrypt \
  postfix \
  \
  nano \
  sudo \
  rsync \
  git \
  unzip \
  wget  \
  curl \
  nano \
  mysql-client \
  && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/apt/archives && \
  rm -rf /usr/share/doc/ && \
  rm -rf /usr/share/man/ && \
  rm -rf /usr/share/locale/

CMD bash
