FROM php:7.1-fpm-alpine

LABEL maintainer="runphp <runphp@qq.com>"

# install nginx
ENV NGINX_VERSION 1.17.0
ENV NJS_VERSION   0.3.2
ENV PKG_RELEASE 1

RUN set -x \
# create nginx user/group first, to be consistent throughout docker variants
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && apkArch="$(cat /etc/apk/arch)" \
    && nginxPackages=" \
        nginx=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-xslt=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-geoip=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-image-filter=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-njs=${NGINX_VERSION}.${NJS_VERSION}-r${PKG_RELEASE} \
    " \
    && case "$apkArch" in \
        x86_64) \
# arches officially built by upstream
            set -x \
            && KEY_SHA512="e7fa8303923d9b95db37a77ad46c68fd4755ff935d0a534d26eba83de193c76166c68bfe7f65471bf8881004ef4aa6df3e34689c305662750c0172fca5d8552a *stdin" \
            && apk add --no-cache --virtual .cert-deps \
                openssl curl ca-certificates \
            && curl -o /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub \
            && if [ "$(openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout | openssl sha512 -r)" = "$KEY_SHA512" ]; then \
                 echo "key verification succeeded!"; \
                 mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/; \
               else \
                 echo "key verification failed!"; \
                 exit 1; \
               fi \
            && printf "%s%s%s\n" \
                "http://nginx.org/packages/mainline/alpine/v" \
                `egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release` \
                "/main" \
            | tee -a /etc/apk/repositories \
            && apk del .cert-deps \
            ;; \
        *) \
# we're on an architecture upstream doesn't officially build for
# let's build binaries from the published packaging sources
            set -x \
            && tempDir="$(mktemp -d)" \
            && chown nobody:nobody $tempDir \
            && apk add --no-cache --virtual .build-deps \
                gcc \
                libc-dev \
                make \
                openssl-dev \
                pcre-dev \
                zlib-dev \
                linux-headers \
                libxslt-dev \
                gd-dev \
                geoip-dev \
                perl-dev \
                libedit-dev \
                mercurial \
                bash \
                alpine-sdk \
                findutils \
            && su - nobody -s /bin/sh -c " \
                export HOME=${tempDir} \
                && cd ${tempDir} \
                && hg clone https://hg.nginx.org/pkg-oss \
                && cd pkg-oss \
                && hg up ${NGINX_VERSION}-${PKG_RELEASE} \
                && cd alpine \
                && make all \
                && apk index -o ${tempDir}/packages/alpine/${apkArch}/APKINDEX.tar.gz ${tempDir}/packages/alpine/${apkArch}/*.apk \
                && abuild-sign -k ${tempDir}/.abuild/abuild-key.rsa ${tempDir}/packages/alpine/${apkArch}/APKINDEX.tar.gz \
                " \
            && echo "${tempDir}/packages/alpine/" >> /etc/apk/repositories \
            && cp ${tempDir}/.abuild/abuild-key.rsa.pub /etc/apk/keys/ \
            && apk del .build-deps \
            ;; \
    esac \
    && apk add --no-cache $nginxPackages \
# if we have leftovers from building, let's purge them (including extra, unnecessary build deps)
    && if [ -n "$tempDir" ]; then rm -rf "$tempDir"; fi \
    && if [ -n "/etc/apk/keys/abuild-key.rsa.pub" ]; then rm -f /etc/apk/keys/abuild-key.rsa.pub; fi \
    && if [ -n "/etc/apk/keys/nginx_signing.rsa.pub" ]; then rm -f /etc/apk/keys/nginx_signing.rsa.pub; fi \
# remove the last line with the packages repos in the repositories file
    && sed -i '$ d' /etc/apk/repositories \
# Bring in gettext so we can get `envsubst`, then throw
# the rest away. To do this, we need to install `gettext`
# then move `envsubst` out of the way so `gettext` can
# be deleted completely, then move `envsubst` back.
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    \
    && runDeps="$( \
        scanelf --needed --nobanner /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache $runDeps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
# Bring in tzdata so users could set the timezones through the environment
# variables
    && apk add --no-cache tzdata \
# forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# add supervisor git bash openssl
RUN apk --no-cache add supervisor git bash openssl openssh

RUN set -xe \
    && apk --no-cache --virtual add linux-headers zlib-dev openssl-dev

RUN set -xe \
    && apk add --no-cache --virtual .build-deps autoconf g++ make pcre-dev re2c

# install some extension
RUN set -xe \
    && apk add --no-cache --virtual libmcrypt-dev
RUN docker-php-ext-install mcrypt

RUN set -xe \
    && apk add --no-cache freetype freetype-dev libpng-dev libjpeg-turbo-dev libwebp-dev \
    && docker-php-ext-configure gd \
       --with-gd \
       --with-freetype-dir=/usr/include/ \
       --with-jpeg-dir=/usr/include/ \
       --with-png-dir=/usr/include/ \
       --with-webp-dir=/usr/include/ \
    && docker-php-ext-install gd

RUN set -xe \
    && apk add --no-cache --virtual icu-dev
RUN docker-php-ext-install intl

RUN set -xe \
    && apk add --no-cache --virtual libxslt-dev
RUN docker-php-ext-install xsl

RUN docker-php-ext-install bcmath
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install zip
RUN docker-php-ext-install soap
RUN docker-php-ext-install sockets
RUN docker-php-ext-install sysvsem
RUN docker-php-ext-install sysvshm
RUN docker-php-ext-install sysvmsg

# compile phalcon extension
ENV PHALCON_VERSION=3.4.3
RUN curl -fsSL https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz -o cphalcon.tar.gz \
    && mkdir -p cphalcon \
    && tar -xf cphalcon.tar.gz -C cphalcon --strip-components=1 \
    && rm cphalcon.tar.gz \
    && cd cphalcon/build \
    && sh install \
    && rm -rf cphalcon \
    && docker-php-ext-enable phalcon

# compile phpiredis extension
RUN apk add hiredis-dev
RUN curl -fsSL https://github.com/nrk/phpiredis/archive/master.zip -o phpiredis.tar.gz \
    && mkdir -p /tmp/phpiredis \
    && tar -xf phpiredis.tar.gz -C /tmp/phpiredis --strip-components=1 \
    && rm phpiredis.tar.gz \
    && docker-php-ext-configure /tmp/phpiredis --enable-phpiredis \
    && docker-php-ext-install /tmp/phpiredis \
    && rm -r /tmp/phpiredis

# compile swoole extension
ENV SWOOLE_VERSION=4.2.9
RUN set -xe \
    && curl -fsSL http://pecl.php.net/get/swoole-${SWOOLE_VERSION}.tgz -o swoole.tar.gz \
    && mkdir -p /tmp/swoole \
    && tar -xf swoole.tar.gz -C /tmp/swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && docker-php-ext-configure /tmp/swoole --enable-swoole --enable-openssl --enable-coroutine\
    && docker-php-ext-install /tmp/swoole \
    && rm -r /tmp/swoole

ENV IGBINARY_VERSION=2.0.5
RUN set -xe \
    && curl -fsSL http://pecl.php.net/get/igbinary-${IGBINARY_VERSION}.tgz -o igbinary.tar.gz \
    && mkdir -p /tmp/igbinary \
    && tar -xf igbinary.tar.gz -C /tmp/igbinary --strip-components=1 \
    && rm igbinary.tar.gz \
    && docker-php-ext-configure /tmp/igbinary --enable-igbinary \
    && docker-php-ext-install /tmp/igbinary \
    && rm -r /tmp/igbinary

ENV MONGODB_VERSION=1.5.3
# compile mongodb extension
RUN set -xe \
    && curl -fsSL http://pecl.php.net/get/mongodb-${MONGODB_VERSION}.tgz -o mongodb.tar.gz \
    && mkdir -p /tmp/mongodb \
    && tar -xf mongodb.tar.gz -C /tmp/mongodb --strip-components=1 \
    && rm mongodb.tar.gz \
    && docker-php-ext-configure /tmp/mongodb --enable-mongodb \
    && docker-php-ext-install /tmp/mongodb \
    && rm -r /tmp/mongodb

ENV MEMCACHED_VERSION=3.0.3
# compile memcached extension
RUN set -xe \
    && apk add --no-cache zlib-dev libmemcached-dev cyrus-sasl-dev \
    && curl -fsSL http://pecl.php.net/get/memcached-${MEMCACHED_VERSION}.tgz -o memcached.tar.gz \
    && mkdir -p /tmp/memcached \
    && tar -xf memcached.tar.gz -C /tmp/memcached --strip-components=1 \
    && rm memcached.tar.gz \
    && docker-php-ext-configure /tmp/memcached --enable-memcached-igbinary --enable-memcached \
    && docker-php-ext-install /tmp/memcached \
    && rm -r /tmp/memcached

ENV REDIS_VERSION=3.1.4
# compile redis extension
RUN set -xe \
    && curl -fsSL http://pecl.php.net/get/redis-${REDIS_VERSION}.tgz -o redis.tar.gz \
    && mkdir -p /tmp/redis \
    && tar -xf redis.tar.gz -C /tmp/redis --strip-components=1 \
    && rm redis.tar.gz \
    && docker-php-ext-configure /tmp/redis --enable-redis \
    && docker-php-ext-install /tmp/redis \
    && rm -r /tmp/redis

ENV APCU_VERSION=5.1.8
# compile apcu extension
RUN set -xe \
    && curl -fsSL http://pecl.php.net/get/apcu-${APCU_VERSION}.tgz -o apcu.tar.gz \
    && mkdir -p /tmp/apcu \
    && tar -xf apcu.tar.gz -C /tmp/apcu --strip-components=1 \
    && rm apcu.tar.gz \
    && docker-php-ext-configure /tmp/apcu --enable-apcu \
    && docker-php-ext-install /tmp/apcu \
    && rm -r /tmp/apcu

ENV RAR_VERSION=4.0.0
# compile rar extension
RUN set -xe \
    && curl -fsSL http://pecl.php.net/get/rar-${RAR_VERSION}.tgz -o rar.tar.gz \
    && mkdir -p /tmp/rar \
    && tar -xf rar.tar.gz -C /tmp/rar --strip-components=1 \
    && rm rar.tar.gz \
    && docker-php-ext-configure /tmp/rar --enable-rar \
    && docker-php-ext-install /tmp/rar \
    && rm -r /tmp/rar

ENV IMAGICK_VERSION=3.4.3
# compile imagick extension imagemagick-dev
RUN set -xe \
    && apk add --no-cache libtool imagemagick-dev \
    && curl -fsSL http://pecl.php.net/get/imagick-${IMAGICK_VERSION}.tgz -o imagick.tar.gz \
    && mkdir -p /tmp/imagick \
    && tar -xf imagick.tar.gz -C /tmp/imagick --strip-components=1 \
    && rm imagick.tar.gz \
    && docker-php-ext-configure /tmp/imagick --enable-imagick \
    && docker-php-ext-install /tmp/imagick \
    && rm -r /tmp/imagick

RUN echo "memory_limit=-1" > "$PHP_INI_DIR/conf.d/memory-limit.ini" \
    && echo "date.timezone=${PHP_TIMEZONE:-UTC}" > "$PHP_INI_DIR/conf.d/date_timezone.ini" \
    && echo "output_buffering=4096" > "$PHP_INI_DIR/conf.d/output_buffering.ini"

RUN mkdir -p /var/www \
    && mkdir -p /etc/nginx/certs \
    && mkdir -p /etc/nginx/conf.d

VOLUME ["/var/www", "/etc/nginx/certs", "/etc/nginx/conf.d"]

COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY etc/nginx/conf.d/_.conf /etc/nginx/conf.d/default.conf

WORKDIR /var/www

ENV PATH="/var/www/docker-php7/bin:${PATH}"

EXPOSE 80 443 9000

STOPSIGNAL SIGTERM

COPY etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
