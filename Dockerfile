FROM php:7.1-fpm-alpine

LABEL maintainer="runphp <runphp@qq.com>"

# add packages
RUN apk add supervisor git bash openssl openssh
RUN apk add autoconf g++ make pcre-dev re2c
RUN apk add linux-headers zlib-dev openssl-dev
RUN apk add libmcrypt-dev icu-dev libxslt-dev
RUN apk add freetype freetype-dev libpng-dev libjpeg-turbo-dev libwebp-dev

# install some extension
RUN docker-php-ext-install gd
RUN docker-php-ext-install intl
RUN docker-php-ext-install xsl
RUN docker-php-ext-install mcrypt
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
RUN mkdir -p /tmp/phpiredis \
    && git clone -b v1.0 https://github.com/runphp/phpiredis.git /tmp/phpiredis \
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

WORKDIR /var/www

ENV PATH="/var/www/docker-php7/bin:${PATH}"

EXPOSE 9000

STOPSIGNAL SIGTERM

COPY etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
