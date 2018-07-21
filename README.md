# php7开发环境

## 使用说明

### 安装docker

<https://www.docker.com/get-docker>

### 检出开发项目和docker配置信息

```sh
git clone https://github.com/runphp/docker-php7

git clone https://gitee.com/eellydev/api.eelly.com
git clone https://gitee.com/eellydev/bbs.eelly.com
git clone https://gitee.com/eellydev/logger.api.eelly.com
git clone https://gitee.com/eellydev/m.eelly.com
git clone https://gitee.com/eellydev/mall.eelly.com
git clone https://gitee.com/eellydev/manage.eelly.com
git clone https://gitee.com/eellydev/passport.eelly.com
git clone https://gitee.com/eellydev/pf.eelly.com
git clone https://gitee.com/eellydev/pifaquan.eelly.com
git clone https://gitee.com/eellydev/so.eelly.com
git clone https://gitee.com/eellydev/uc.eelly.com
git clone https://gitee.com/eellydev/www.eelly.com

# linux
docker run -p 80:80 -p 443:443 -p 9501:9501 -d \
    --name=eelly-php7 \
    -v ~/.ssh:/root/.ssh \
    -v $PWD:/var/www \
    -v $PWD/composer:/root/.composer \
    -v $PWD/docker-php7/etc/nginx/certs:/etc/nginx/certs \
    -v $PWD/docker-php7/etc/nginx/conf.d:/etc/nginx/conf.d \
    -v $PWD/docker-php7/etc/php-fpm.d:/usr/local/etc/php-fpm.d \
    eelly/php7

# windows 需要绝对路径
docker run -p 80:80 -p 443:443 -p 9501:9501 -d \
    --name=eelly-php7 \
    -v D:/workspace/php/.ssh:/root/.ssh \
    -v D:/workspace/php:/var/www \
    -v D:/workspace/php/composer:/root/.composer \
    -v D:/workspace/php/docker-php7/etc/nginx/certs:/etc/nginx/certs \
    -v D:/workspace/php/docker-php7/etc/nginx/conf.d:/etc/nginx/conf.d \
    -v D:/workspace/php/docker-php7/etc/php-fpm.d:/usr/local/etc/php-fpm.d \
    eelly/php7

# windows mariadb server
docker run -p 3306:3306 \
    --name=eelly-mariadb \
    -e MYSQL_ROOT_PASSWORD=123456 \
    -d mariadb
```

### 运行composer

```sh
# linux
docker exec -it eelly-php7 composer install -d api.eelly.dev -vvv
# windows
winpty docker exec -it eelly-php7 composer install -d api.eelly.dev -vvv
```
