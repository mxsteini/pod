# Podman

## Inital setup

## Add new project

1. Create database
```sh
mysql -h 127.0.0.1 -u root -p
```
2. Create vhost
```sh
~/.cyzpod/etc/apache2/sites-enabled
```

3. restart 
```sh
pod.sh --restart
```

4. update /etc/hosts by appending the domain name to the list of localhost domains
```sh
use your editor to edit the file
```

5. Run composer from typo3 dir of project
```sh
pod.sh --composer7.2 install 
```

Another restart might be required at this point.
 
6. Run typo3 console from typo3 dir of project. Replace the placeholders
```sh
 pod.sh --console7.2 vendor/bin/typo3cms install:setup --force --no-interaction --database-user-name root --database-user-password root --database-name DATABASENAME --admin-user-name vagrant --admin-password vagrant1 --use-existing-database --site-name "PROJECTKEY.vagrant/vagrant"
```

7. Import database. Replace the placeholders and use the super secrect password `root`
```sh
mysql -h 127.0.0.1 -u root -p DATABASENAME < DATABASEFILEPATH.sql
```

## Troubleshooting

### An exception occurred in driver: No such file or directory
Make sure the db settings are correct and the db host is `127.0.0.1` and not `localhost`.
