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
    ;;
  --composer)
    command='composer'
    shift
    version=$1
    shift
    ;;
  --console)
    command='console'
    shift
    version=$1
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
  --init)
    command='init'
    shift
    ;;
  --install)
    command='install'
    shift
    ;;
  --createProject)
    command='createProject'
    shift
    projectName=$1
    shift
    ;;
  esac
done

case "${command}" in
init)
  defaultDir=`pwd`

  read -p "Please enter projects dir [$defaultDir]: " projectDir
  projectDir=${projectDir:-${defaultDir}}

  echo 'projectDir="'$projectDir'"' > ~/.cyzpod/config
  ;;
install)
  install -m 777 -d ~/.cyzpod/database
  install -m 777 -d ~/.cyzpod/log
  cp -r etc ~/.cyzpod/
  install pod.sh ~/bin/pod.sh
  ;;
build)
  podman build --tag composer:7.2 -f Dockerfiles/composer7.2
#  podman build --tag myfpm:7.2 -f Dockerfiles/php7.2
  podman build --tag myfpm-alpine:7.2 -f Dockerfiles/php7.2-alpine
#  podman build --tag composer:7.3 -f Dockerfiles/composer7.3
#  podman build --tag myfpm:7.3 -f Dockerfiles/php7.3
  ;;
create)
    source ~/.cyzpod/config
  podman pod create --infra --name cyzpod \
    -p 8080:80 -p 3306:3306
  podman run -dit \
    --pod cyzpod \
    --name httpd \
    --volume $projectDir/:/var/www/html/:z \
    --volume ~/.cyzpod/log/:/usr/local/apache2/logs/:Z \
    --volume ~/.cyzpod/etc/apache2/:/usr/local/apache2/conf/:Z \
    httpd:2.4
  podman run -dit \
    --pod cyzpod \
    --name php72 \
    --volume ~/.cyzpod/log/:/var/log/:z \
    --volume $projectDir/:/var/www/html/:z \
    --volume ~/.cyzpod/etc/php7.2/:/usr/local/etc/php-fpm.d/:z \
    myfpm-alpine:7.2 \
    php-fpm -R
#  podman run -dit \
#    --pod cyzpod \
#    --name php73 \
#    --volume ~/.cyzpod/log/:/var/log/:z \
#    --volume $projectDir/:/var/www/html/:z \
#    --volume ~/.cyzpod/etc/php7.3/:/usr/local/etc/php-fpm.d/:z \
#    myfpm:7.3 \
#    php-fpm -R
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
console)
  source ~/.cyzpod/config
  pwd=`pwd`
  defaultDocumentRoot=${pwd#"$projectDir/"}
  podman run --name console${version} --rm --interactive --tty \
    --pod cyzpod \
    --volume ~/.cyzpod/log/:/var/log/:z \
    --volume $pwd:/var/www/html/$defaultDocumentRoot:z \
    --volume ~/.cyzpod/etc/php${version}/cli:/usr/local/etc/php:z \
    myfpm-alpine:${version} sh -c "cd /var/www/html/$defaultDocumentRoot && $*"
  ;;
composer)
  source ~/.cyzpod/config
  pwd=`pwd`
  defaultDocumentRoot=${pwd#"$projectDir/"}
  command="cd /var/www/html/$defaultDocumentRoot && $@"
  podman run --name composer${version} --rm --interactive --tty \
    --volume $pwd:/var/www/html/$defaultDocumentRoot:z \
    --volume ~/.ssh:/root/.ssh:Z \
    --volume ~/.composer:/tmp:Z \
    --volume $PWD:/app/:Z \
    composer:${version} sh -c "cd /var/www/html/$defaultDocumentRoot && $*"
  ;;
down)
  podman stop --all
  ;;
rm)
  pod.sh --down
  podman rm httpd
  podman rm php72
#  podman rm php73
  podman rm db
  podman pod rm cyzpod
  ;;
createProject)
  source ~/.cyzpod/config

  if [[ $projectName == '' ]]; then
    echo -e '\033[0;31m'Error No project name specified
    exit
  fi

  sitesPath=~/.cyzpod/etc/apache2/sites-enabled/020-"$projectName".conf

  if [ -f "$sitesPath" ]; then
    echo -e '\033[0;31m'Error project already exists
    exit
  fi

  defaultProjectType='php72'
  read -p "Please enter project type [$defaultProjectType]: " projectType
  projectType=${projectType:-${defaultProjectType}}

  skelPath=~/.cyzpod/etc/apache2/sites-enabled/"$projectType".skel

  if [ ! -f "$skelPath" ]; then
    echo -e '\033[0;31m'Error No such project type "$projectType"
    exit
  fi

  pwd=`pwd`
  defaultDocumentRoot=${pwd#"$projectDir/"}

  read -p "Please enter document root [$defaultDocumentRoot]: " documentRoot
  documentRoot=${documentRoot:-${defaultDocumentRoot}}

  read -p "Please enter a database name [$projectName]: " databaseName
  databaseName=${databaseName:-${projectName}}

  cp "$skelPath" "$sitesPath"

  mysql -h 127.0.0.1 -u root -proot -e "create database $databaseName;"

  sed -i "s|###DOCUMENTROOT###|$documentRoot|g" $sitesPath
  sed -i "s|###SERVERNAME###|$projectName.pod|g" $sitesPath

  ;;
esac
exit
