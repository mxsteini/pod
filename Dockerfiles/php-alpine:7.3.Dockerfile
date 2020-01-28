FROM php:7.3-fpm-alpine
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories
RUN apk add --no-cache ghostscript graphicsmagick freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev libxml2-dev icu-dev g++ libzip-dev && \
  docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ && \
  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null) && \
  docker-php-ext-install -j${NPROC} gd && \
  docker-php-ext-configure zip --with-libzip=/usr/include && \
  apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev

RUN docker-php-ext-install mysqli pdo pdo_mysql && \
	docker-php-ext-install opcache && \
	docker-php-ext-install soap && \
	docker-php-ext-install zip intl

#
#RUN apk add --no-cache zlib-dev icu-dev g++ && \
#  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
#  docker-php-ext-install -j${NPROC} intl && \
#  apk del --no-cache zlib-dev icu-dev g++





