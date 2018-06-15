#!/usr/bin/env bash


cd /var/www/api.eelly.com
git pull -X theirs origin master

cd /var/www/docker-php7.eelly.com
git pull -X theirs origin master

cd /var/www/mall.eelly.com
git pull -X theirs origin master

cd /var/www/manage.eelly.com
git pull -X theirs origin master

cd /var/www/passport.eelly.com
git pull -X theirs origin master

cd /var/www/so.eelly.com
git pull -X theirs origin master

cd /var/www/uc.eelly.com
git pull -X theirs origin master

cd /var/www/www.eelly.com
git pull -X theirs origin master