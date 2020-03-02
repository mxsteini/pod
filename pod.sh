#!/usr/bin/env bash

command=$1
shift

case $command in
console | composer | runPhp)
  version=$1
  shift
  ;;
enter | restart)
  container=$1
  shift
  ;;
createProject)
  projectName=$1
  shift
  ;;
esac

pod_prefix=cyz_
source ~/.cyzpod/config
echo running $command
case "${command}" in
init)
  defaultDir=$(pwd)

  read -p "Please enter projects dir [$defaultDir]: " projectDir
  projectDir=${projectDir:-${defaultDir}}

  echo 'projectDir="'$projectDir'"' >~/.cyzpod/config
  ;;
install)
  install -m 777 -d ~/.cyzpod/database
  install -m 777 -d ~/.cyzpod/log
  cp -r etc ~/.cyzpod/
  install pod.sh ~/bin/pod.sh
  ;;
build)
  find Dockerfiles -type f -name "*.Dockerfile" | while read dockerfile; do
    if [[ "$dockerfile" -nt ./Dockerfiles/lastbuild || ! -f ./Dockerfiles/lastbuild ]]; then
      imagename=$(basename "$dockerfile" .Dockerfile)
      echo $imagename
      podman build --tag $imagename -f "$dockerfile"
    fi
  done
  touch ./Dockerfiles/lastbuild
  ;;
create)
  podman pod create --infra --name ${pod_prefix}pod \
    -p 8080:80 -p 3306:3306 -p 3000:3000 -p 1025:1025 -p 8025:8025
  pod.sh runMailhog
  pod.sh runHttpd
  pod.sh runDb
  ;;
runMailhog)
  podman run -dit \
    --pod ${pod_prefix}pod \
    --name ${pod_prefix}mailschwein \
    mailhog/mailhog:latest
  ;;
runHttpd)
  podman run -dit \
    --pod ${pod_prefix}pod \
    --name ${pod_prefix}httpd \
    --volume $projectDir/:/var/www/html/:ro \
    --volume ~/.cyzpod/log/:/usr/local/apache2/logs/:z \
    --volume ~/.cyzpod/etc/apache2/:/usr/local/apache2/conf/:Z \
    httpd:2.4-alpine
  ;;
runPhp)
  podman run -dit \
    --pod ${pod_prefix}pod \
    --name ${pod_prefix}php${version} \
    --volume $projectDir/:/var/www/html/:Z \
    --volume ~/.cyzpod/log/:/var/log/:z \
    --volume ~/.cyzpod/etc/php${version}/:/usr/local/etc/php-fpm.d/:Z \
    localhost/php-alpine:${version} \
    php-fpm -R
  ;;
runDb)
  podman run -dit \
    --pod ${pod_prefix}pod \
    --name ${pod_prefix}db \
    --env MARIADB_ROOT_PASSWORD=root \
    --volume ~/.cyzpod/database/:/bitnami/mariadb:Z \
    bitnami/mariadb:latest
  ;;
elasticsearch)
  podman run -dit \
    --pod ${pod_prefix}pod \
    --name elsearch \
    --volume ~/.cyzpod/database/elasticsearch:/usr/share/elasticsearch/data:Z \
    --env "discovery.type=single-node" \
    elasticsearch:2.4.6
  ;;
enter)
  podman exec -it \
    $container \
    sh
  ;;
console)
  pwd=$(pwd)
  defaultDocumentRoot=${pwd#"$projectDir/"}
  podman exec -it ${pod_prefix}php${version} \
    sh -c "cd /var/www/html/$defaultDocumentRoot && $*"
  ;;
composer)
  pwd=$(pwd)
  defaultDocumentRoot=${pwd#"$projectDir/"}
  podman run --name composer${version} --rm --interactive --tty \
    --volume $pwd:/var/www/html/$defaultDocumentRoot:z \
    --volume ~/.ssh:/root/.ssh:Z \
    --volume ~/.composer:/tmp:Z \
    --volume $PWD:/app/:Z \
    composer:${version} sh -c "cd /var/www/html/$defaultDocumentRoot && $*"
  ;;
restart)
  if [ $container ]; then
    podman container restart $container
  else
    podman pod restart ${pod_prefix}pod
  fi
  ;;
restartHttp)
  podman exec -it ${pod_prefix}httpd sh -c "kill -USR1 1"
  ;;
up)
  podman pod start ${pod_prefix}pod
  ;;
down)
  podman pod stop ${pod_prefix}pod
  ;;
rm)
  ./pixelpod.sh --down
  podman pod rm -f ${pod_prefix}pod
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

  pwd=$(pwd)
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
*)
  echo command not found
  ;;
esac
exit
