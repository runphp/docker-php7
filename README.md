# php7开发环境

## 使用说明

1. 安装docker
<https://www.docker.com/get-docker>
2. 检出开发项目和docker配置信息
```
git clone https://gitee.com/eellydev/api.eelly.com api.eelly.dev
git clone https://gitee.com/eellydev/www www.blty.dev
git clone https://github.com/runphp/docker-php7
docker run -p 80:80 -p 443:443 \
    -v $PWD:/var/www \
    -v docker-php7/etc/nginx/certs:/etc/nginx/certs \
    -v docker-php7/etc/nginx/conf.d:/etc/nginx/conf.d \
    eelly/php7
```
