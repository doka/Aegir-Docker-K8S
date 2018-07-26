# Run Aegir in Docker or Kubernetes

This is a Docker and Kubernetes environment to run, test and develop Aegir.

Images are based on PHP 7.0 and Apache2, and mariadb:
- [Debian 9 / Stretch](https://cloud.docker.com/swarm/wepoca/repository/docker/wepoca/stretch-php7).
- [Ubuntu 16.04 LTS](https://cloud.docker.com/swarm/wepoca/repository/docker/wepoca/lts-php7).

## Usage in Docker:
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

## Usage in Kubernetes:
1. read and change k8s-deployment.yaml:
  - set `AEGIR_VERSION` as you wish
  - change database root password (as secret)
  - optionally, adapt storage settings to your cluster setup

2. use k8s-deployment.yaml to start up volumes, services and deployments to fly :)
  - start up using wepoca/aegir image:

    `kubectl create -f k8s-deployment.yaml`

3. check status:
  - `kubectl get all`

4. shut down:
    - full shutdown, including remove of all data on persistent volumes:

      `kubectl delete -f k8s-deployment.yaml`
