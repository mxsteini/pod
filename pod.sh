#!/usr/bin/env bash

# if [ "$(id -u)" != "33" ]; then
# 	echo "This script must be run as www-data" 1>&2
# 	echo "sudo su www-data - -s /bin/bash -c $0" 1>&2
# 	exit 1
# fi

mode='--dry-run'
command='rsync'

source='/var/www/dev.pixelmat.ch'
target='/var/www/www.pixelmat.ch'

for i in "$@"; do
  case $i in
  --up)
    command='up'
    shift
    ;;
  --down)
    command='down'
    shift
    ;;
  --create)
    command='create'
    shift
    ;;
  --composer7.3)
    command='composer7.3'
    shift
    ;;
  --composer7.2)
    command='composer7.2'
    shift
    ;;
  --console7.2)
    command='console7.2'
    shift
    ;;
  --enter)
    command='enter'
    shift
    echo $1
    container=$1
    shift
    ;;
  --restart)
    command='restart'
    shift
    ;;
  --build)
    command='build'
    shift
    ;;
  --rm)
    command='rm'
    shift
    ;;
  esac
done

case "${command}" in
build)
#  podman build --tag composer:7.3 -f Dockerfiles/composer7.3
  podman build --tag composer:7.2 -f Dockerfiles/composer7.2
#  podman build --tag myfpm:7.3 -f Dockerfiles/php7.3
  podman build --tag myfpm:7.2 -f Dockerfiles/php7.2
  ;;
create)
  podman pod create --infra --name cyzpod \
    -p 8080:80 -p 3306:3306
  podman run -dit \
    --pod cyzpod \
    --name httpd \
    --volume ~/Projekte/:/var/www/:z \
    --volume ~/Projekte/Docker/log/:/usr/local/apache2/logs/:Z \
    --volume ~/Projekte/Docker/etc/apache2/:/usr/local/apache2/conf/:Z \
    httpd:2.4
  podman run -dit \
    --pod cyzpod \
    --name php72 \
    --volume ~/Projekte/Docker/log/:/var/log/:z \
    --volume ~/Projekte/:/var/www/html/:z \
    --volume ./etc/php7.2/:/usr/local/etc/php-fpm.d/:z \
    myfpm:7.2 \
    php-fpm -R
  podman run \
    --env MARIADB_USER=vagrant \
    --env MARIADB_PASSWORD=vagrant \
    --env MARIADB_DATABASE=vagrant \
    --env MARIADB_ROOT_PASSWORD=root \
    --pod cyzpod \
    --name db \
    --volume ~/Projekte/Docker/db/:/var/lib/mysql/:Z \
    -d bitnami/mariadb:latest
  ;;
enter)
  podman exec -it \
    $container \
    /bin/bash
  ;;
restart)
  ./pod.sh --down
  ./pod.sh --up
  ;;
up)
  podman pod start cyzpod
  ;;
console7.2)
  podman run --name console7.2 --rm --interactive --tty \
    --pod cyzpod \
    --volume ~/Projekte/Docker/log/:/var/log/:z \
    --volume $PWD:/var/www/html/:z \
    --volume ~/Projekte/Docker/etc/php7.2/:/usr/local/etc/php-fpm.d/:z \
    myfpm:7.2 "$@"
  ;;
composer7.2)
  podman run --name composer7.2 --rm --interactive --tty \
    --volume ~/.composer:/tmp:Z \
    --volume $PWD:/app/:Z \
    composer:7.2 "$@"
  ;;
down)
  podman stop --all
  ;;
rm)
  ./pod.sh --down
  podman rm httpd
  podman rm php72
  podman rm db
  podman pod rm cyzpod
  ;;
esac
exit
