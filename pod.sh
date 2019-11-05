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

for i in "$@"
do
case $i in
    -u|--up)
    command='up'
    shift
    ;;
    -d|--down)
    command='down'
    shift
    ;;
    -p|--pull)
    command='pull'
    shift
    ;;
    -c|--create)
    command='create'
    shift
    ;;
    -r|--rm)
    command='rm'
    shift
    ;;
  esac
done
#      -e HTTPD_LOG_TO_VOLUME=1 \
#      --volume /home/mst/Projekte/Docker/wwwlogs:/var/log/httpd24:Z \
#      --volume /home/mst/Projekte/Docker/apache2/:/usr/local/apache2/conf/ \
case "${command}" in
  create2)
    podman pod create --infra --name cyzpod -p 8080:8080
    podman run -dit \
      -u 0 \
      --pod cyzpod \
      --name httpd \
      -e HTTPD_LOG_TO_VOLUME=1 \
      --volume /home/mst/Projekte/Docker/wwwlogs:/var/log/httpd24:Z \
      --volume /home/mst/Projekte/Docker/:/var/www:Z \
      --volume /home/mst/Projekte/Docker/bain/:/var/www/bain:Z \
      rhscl/httpd-24-rhel7
    ;;
  create)
    podman pod create --infra --name cyzpod -p 8080:80 -p 3306
    podman run -dit \
      --pod cyzpod \
      --name httpd \
      --volume /home/mst/Projekte/BAIN3/typo3/:/var/www/:z \
      --volume /home/mst/Projekte/Docker/logs/:/usr/local/apache2/logs/:Z \
      --volume /home/mst/Projekte/Docker/etc/apache2/:/usr/local/apache2/conf/:Z \
      httpd:2.4
    podman run -dit \
      --pod cyzpod \
      --name php72 \
      --volume /home/mst/Projekte/BAIN3/typo3/:/var/www/html/:Z \
      php:7.2-fpm
    podman run -dit \
      --pod cyzpod \
      --name db \
      --volume /home/mst/Projekte/Docker/db/:/var/lib/mysql:Z \
      -e MYSQL_ROOT_PASSWORD=root \
      mariadb:latest
#      cat /usr/local/apache2/conf/original/httpd.conf
#      cat /usr/local/apache2/conf/extra/proxy-html.conf
#      cat /var/www/index.html
    ;;
  up)
    podman pod start cyzpod
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
#      --volume /home/mst/Projekte/Docker/html/:/usr/local/apache2/htdocs/:z \
#      --volume /home/mst/Projekte/Docker/apache2/:/usr/local/apache2/conf/:Z \
