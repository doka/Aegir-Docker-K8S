# Run Aegir in Docker

This is a Docker environment to run, test and develop Aegir in Docker.

Images are based on:
- [stretch](https://cloud.docker.com/swarm/wepoca/repository/docker/wepoca/stretch-php7): Debian 9 and Ubuntu 16.04 LTS.
- [lts](https://cloud.docker.com/swarm/wepoca/repository/docker/wepoca/lts-php7): PHP 7.0 and Apache2, and mariadb

## Usage:
1. read and change docker-compose.yml:
  - change `MYSQL_ROOT_PASSWORD` (for both services!)
  - set `AEGIR_VERSION` as you wish

2. choose images:
  - default is to download images from [wepoca/aegir](https://cloud.docker.com/swarm/wepoca/repository/docker/wepoca/aegir)
  - to use your local build, uncomment `line build: .` and
    remove the line `image: wepoca/aegir`

3. use docker-compose.yml to start up volumes, containers to fly :)
  - start up using wepoca/aegir:

    `docker-compose up`
  - or start up using your own local builds:

    `docker-compose up --build`
4. shut down:
  - stop containers, but maintain persistent data:

    `docker-compose down`
  - full shutdown, including remove of all data on persistent volumes:

    `docker-compose down --volume`
