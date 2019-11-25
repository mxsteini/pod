#!/usr/bin/env bash

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
    projects=$1
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
  --installMe)
    command='installMe'
    shift
    ;;
  esac
done

case "${command}" in
installMe)
  ln -s $SCRIPT ~/bin
  mkdir -p ~/.cyzpod/database
  mkdir -p ~/.cyzpod/log/
  cp -r etc ~/.cyzpod/
  ;;
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
    --volume $projects/:/var/www/:z \
    --volume ~/.cyzpod/log/:/usr/local/apache2/logs/:Z \
    --volume ~/.cyzpod/etc/apache2/:/usr/local/apache2/conf/:Z \
    httpd:2.4
  podman run -dit \
    --pod cyzpod \
    --name php72 \
    --volume ~/.cyzpod/log/:/var/log/:z \
    --volume $projects/:/var/www/html/:z \
    --volume ~/.cyzpod/etc/php7.2/:/usr/local/etc/php-fpm.d/:z \
    myfpm:7.2 \
    php-fpm -R
  podman run -dit \
    --env MARIADB_USER=vagrant \
    --env MARIADB_PASSWORD=vagrant \
    --env MARIADB_DATABASE=vagrant \
    --env MARIADB_ROOT_PASSWORD=root \
    --pod cyzpod \
    --name db \
    --volume ~/.cyzpod/database/:/bitnami/mariadb:Z \
    bitnami/mariadb:latest
  ;;
enter)
  podman exec -it \
    $container \
    /bin/bash
  ;;
restart)
  pod.sh --down
  pod.sh --up
  ;;
up)
  podman pod start cyzpod
  ;;
console7.2)
  podman run --name console7.2 --rm --interactive --tty \
    --pod cyzpod \
    --volume ~/.cyzpod/log/:/var/log/:z \
    --volume $PWD:/var/www/html/:z \
    --volume ~/.cyzpod/etc/php7.2/:/usr/local/etc/php-fpm.d/:z \
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
  pod.sh --down
  podman rm httpd
  podman rm php72
  podman rm db
  podman pod rm cyzpod
  ;;
esac
exit
