#!/usr/bin/env bash

command=$1
shift

case $command in
console | wpcli | composer | runPhp | runBPhp)
  version=$1
  shift
  ;;
enter | restart | serverList)
  container=$1
  shift
  ;;
createProject)
  projectName=$1
  shift
  ;;
esac

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
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
  [[ -f create.local.sh ]] && install create.local.sh ~/bin/create.local.sh
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
  podman pod rm -f ${pod_prefix}pod
  podman pod create \
    --infra --name ${pod_prefix}pod \
    -p 8080:80 -p 3306:3306 -p 3000:3000 -p 8025:8025 -p 1025:1025 -p 8983:8983 -p 9200:9200 -p 5000:5000
  $SCRIPTPATH/pod.sh runHttpd
  $SCRIPTPATH/pod.sh runMailhog
  $SCRIPTPATH/pod.sh runDb
  $SCRIPTPATH/pod.sh runPhp 7.2
  $SCRIPTPATH/pod.sh runBPhp 7.4
  [[ -f ~/bin/create.local.sh ]] && source ~/bin/create.local.sh
  ;;
runMailhog)
  podman run -d \
    --security-opt label=disable \
    --pod ${pod_prefix}pod \
    --name ${pod_prefix}mailschwein \
    mailhog/mailhog:latest
  ;;
runHttpd)
  podman container rm -f ${pod_prefix}httpd
  echo $projectDir
  podman run -d \
    --security-opt label=disable \
    --pod ${pod_prefix}pod \
    --name ${pod_prefix}httpd \
    --mount type=bind,src=$projectDir,dst=/var/www/html \
    --volume ~/.cyzpod/log/:/usr/local/apache2/logs/:z \
    --volume ~/.cyzpod/etc/apache2/:/usr/local/apache2/conf/:Z \
    httpd:2.4-alpine
  ;;
runRedis)
  podman container rm -f ${pod_prefix}redis
  podman run -d \
    --security-opt label=disable \
    --pod ${pod_prefix}pod \
    --name ${pod_prefix}redis \
    redis:6
  ;;
runPhp)
  podman container rm -f ${pod_prefix}php${version}
  podman run -d \
    --security-opt label=disable \
    --pod ${pod_prefix}pod \
    --name ${pod_prefix}php${version} \
    --mount type=bind,src=$projectDir,dst=/var/www/html \
    --volume ~/.cyzpod/log/:/var/log/:z \
    --volume ~/bin/:/opt/bin/:z \
    --volume ~/.cyzpod/etc/php${version}/:/usr/local/etc/php-fpm.d/:Z \
    --volume ~/.cyzpod/etc/php${version}/cli/:/usr/local/etc/php/:Z \
    localhost/php-alpine:${version} \
    php-fpm -R
  ;;
runBPhp)
  podman container rm -f ${pod_prefix}php${version}
  podman run -d \
    --security-opt label=disable \
    --pod ${pod_prefix}pod \
    --name ${pod_prefix}php${version} \
    --mount type=bind,src=$projectDir,dst=/var/www/html \
    --volume ~/bin/:/opt/bin/:z \
    --volume ~/.cyzpod/log/:/var/log/:z \
    --volume ~/.cyzpod/etc/ImageMagick-6/:/etc/ImageMagick-6/:Z \
    --volume ~/.cyzpod/etc/php${version}/:/usr/local/etc/:Z \
    localhost/php-buster:${version} \
    php-fpm -R
  ;;
runDb)
  podman run -d \
    --security-opt label=disable \
    --pod ${pod_prefix}pod \
    --name ${pod_prefix}db \
    --env MARIADB_ROOT_PASSWORD=root \
    --volume ~/.cyzpod/etc/mysql/:/etc/mysql/conf.d/:Z \
    --mount type=bind,src=$HOME/.cyzpod/database,dst=/bitnami/mariadb \
    bitnami/mariadb:latest
  ;;
elasticsearch)
  podman run -d \
    --security-opt label=disable \
    --pod ${pod_prefix}pod \
    --name elsearch \
    --mount type=bind,src=$HOME/.cyzpod/database/elasticsearch,dst=/usr/share/elasticsearch/data \
    --env "discovery.type=single-node" \
    --env "ES_JAVA_OPTS=-Xms256m -Xmx256m" \
    elasticsearch:5.6.16
  ;;
solr)
  podman container rm -f solr
  podman run -d \
    --security-opt label=disable \
    --add-host '*.localhost:127.0.0.1' \
    --pod ${pod_prefix}pod \
    --name solr \
    --volume ~/.cyzpod/database/solr:/opt/solr/server/solr:Z \
    solr:7.6.0
  ;;
elasticsearchHq)
  podman run -d \
    --security-opt label=disable \
    --pod ${pod_prefix}pod \
    --name elsearchhq \
    elastichq/elasticsearch-hq
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
wpcli)
  pwd=$(pwd)
  defaultDocumentRoot=${pwd#"$projectDir/"}
  podman exec -it ${pod_prefix}php${version} \
    sh -c "cd /var/www/html/$defaultDocumentRoot && wp --allow-root $*"
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
  sed -i "s|###SERVERNAME###|$projectName.localhost|g" $sitesPath

  pod.sh restartHttp
  ;;
serverList)
  #  grep -r "ServerName (.*)"  ~/.cyzpod/etc/apache2/sites-enabled/*
  serverNames=$(awk '$1 == "ServerName" {printf "%s ",$2}' ~/.cyzpod/etc/apache2/sites-enabled/*.conf)
  serverNames=$serverNames":127.0.0.1"
#  serverNames=$(echo $serverNames | awk '{print tolower($0)}')
#  podman exec -it \
#    $container \
#    sh -c "echo \"$serverNames\" >> /etc/hosts"
#  echo added hosts to $container
  ;;
*)
  echo command not found
  ;;
esac
exit
