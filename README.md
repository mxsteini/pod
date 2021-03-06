# pod.sh

NOTE: Below instructions are outdated.

## Initial setup

### Install helper script
This will install the pod.sh script to `~/bin`. Pleas make sure your PATH contains this directory.
```sh
# install
./pod.sh install
# init
pod.sh init
```

### Build containers
run this command in the downloaded folder
```sh
./pod.sh build
```

### Create and run pods
```sh
pod.sh create
```

## How to run

### Starting the containers
```sh
pod.sh up
```

## Adding a TYPO3 project

1. Creating the project
```sh
pod.sh createProject
```
 
2. Run typo3 console from typo3 dir of project. Replace the placeholders
```sh
 pod.sh console[PHP version] vendor/bin/typo3cms install:setup --force --no-interaction --database-user-name root --database-user-password root --database-name DATABASENAME --admin-user-name vagrant --admin-password vagrant1 --use-existing-database --site-name "PROJECTKEY.vagrant/vagrant"
```

3. Import database. Replace the placeholders and use the super secrect password `root`
```sh
mysql -h 127.0.0.1 -u root -p DATABASENAME < DATABASEFILEPATH.sql
```

## Troubleshooting

### An exception occurred in driver: No such file or directory

Make sure the db settings are correct and the db host is `127.0.0.1` and not `localhost`.

## Command reference

### createProject PROJECTNAME
Creates a project of name PROJECTNAME by creating a database and the apache2 vhost.

### init
Asks for the project directory and stores it in `~/.cyzpod/config`.

### install
Installs the pod.sh script to `~/bin` and all other required files and directories to `~/.cyzpod`.

### up
Starts the cyzpod/all containers.

### down
Brings down the cyzpod/all containers.

### create
Creates cyzpod and starts it.

### console
TODO: Add description.

### restart
Restart all containers.
Same as 
```sh
pod.sh down
pod.sh up
```

### enter CONTAINER
Starts shell in CONTAINER .

### build
Build required containers. Must be run from the root directory of this repo.

### rm
Removes cypod and it's containers.


