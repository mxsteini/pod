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
  -u | --up)
    command='up'
    shift
    ;;
  -d | --down)
    command='down'
    shift
    ;;
  -p | --pull)
    command='pull'
    shift
    ;;
  -c | --create)
    command='create'
    shift
    ;;
  --composer7.3)
    command='composer7.3'
    shift
    ;;
  --console)
    command='console'
    shift
    ;;
  --php)
    command='php'
    shift
    ;;
  --build)
    command='build'
    shift
    ;;
  -r | --rm)
    command='rm'
    shift
    ;;
  esac
done
#      -e HTTPD_LOG_TO_VOLUME=1 \
#      --volume /home/mst/Projekte/Docker/wwwlogs:/var/log/httpd24:Z \
#      --volume /home/mst/Projekte/Docker/apache2/:/usr/local/apache2/conf/ \
case "${command}" in
build)
  podman build --tag composer:7.3 -f Dockerfiles/composer7.3
  #  podman build --tag myfpm:7.3 -f Dockerfiles/php7.3
  #  podman build --tag myfpm:7.2 -f Dockerfiles/php7.2
  #  podman build --tag mycomposer -f Dockerfiles/composer7.3
  ;;
php)
  podman run -it \
    --name testphp \
    --volume /home/mst/Projekte/Docker/log/:/var/log/:Z \
    --volume /home/mst/Projekte/BAIN3/typo3/:/var/www/html/:z \
    --volume ./etc/php7.2/:/usr/local/etc/php-fpm.d/:z \
    myfpm:7.2 \
    /bin/bash
  ;;
create)
  podman pod create --infra --name cyzpod -p 8080:80 -p 3306
  podman run -dit \
    --pod cyzpod \
    --name httpd \
    --volume /home/mst/Projekte/BAIN3/typo3/:/var/www/:z \
    --volume /home/mst/Projekte/Docker/log/:/usr/local/apache2/logs/:Z \
    --volume /home/mst/Projekte/Docker/etc/apache2/:/usr/local/apache2/conf/:Z \
    httpd:2.4
  podman run -dit \
    --pod cyzpod \
    --name php72 \
    --volume /home/mst/Projekte/Docker/log/:/var/log/:Z \
    --volume /home/mst/Projekte/BAIN3/typo3/:/var/www/html/:Z \
    --volume ./etc/php7.2/:/usr/local/etc/php-fpm.d/:z \
    myfpm:7.3 \
    php-fpm -R
  podman run -dit \
    --pod cyzpod \
    --name db \
    --volume /home/mst/Projekte/Docker/db/:/var/lib/mysql:Z \
    -e MYSQL_ROOT_PASSWORD=root \
    mariadb:latest
  ;;
console)
  podman run -it \
    --volume /home/mst/Projekte/Docker/log/:/var/log/:Z \
    --volume /home/mst/Projekte/BAIN3/typo3/:/var/www/html/:Z \
    --volume ./etc/php7.2/:/usr/local/etc/php-fpm.d/:z \
    myfpm:7.3 \
    /bin/bash
  ;;
up)
  podman pod start cyzpod
  ;;
composer7.3)
  podman run --name mycomposer --rm --interactive --tty \
    --volume ${COMPOSER_HOME:-$HOME/.composer}:/tmp \
    --volume /home/mst/Projekte/BAIN3/typo3/:/app/:Z \
    composer:7.3 $@ --no-scripts
  ;;
down)
  podman pod stop cyzpod
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

#      --volume /home/mst/Projekte/Docker/html/:/usr/local/apache2/htdocs/:z \
#      --volume /home/mst/Projekte/Docker/apache2/:/usr/local/apache2/conf/:Z \

#--privileged \
#--user 1000:1000 \
#  --security-opt label=disable
