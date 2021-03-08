FROM php:7.4-fpm
RUN apt-get update
RUN apt-get install -y ghostscript graphicsmagick libfreetype6 libpng-dev libjpeg62-turbo libfreetype6-dev libjpeg62-turbo-dev libxml2-dev libicu-dev g++ libzip-dev

RUN docker-php-ext-install mysqli pdo pdo_mysql && \
	docker-php-ext-install opcache && \
	docker-php-ext-install soap && \
	docker-php-ext-install zip intl

RUN pecl install -o -f redis \
	&&  rm -rf /tmp/pear \
	&&  docker-php-ext-enable redis

#
#RUN apk add --no-cache zlib-dev icu-dev g++ && \
#  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
#  docker-php-ext-install -j${NPROC} intl && \
#  apk del --no-cache zlib-dev icu-dev g++

RUN DEBIAN_FRONTEND=noninteractive apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y \
      curl \
      git \
      zip unzip \
      lbzip2

RUN docker-php-ext-install \
      bcmath \
      calendar \
      exif \
      gd \
      intl

RUN docker-php-ext-install \
      mysqli \
      opcache \
      pdo_mysql

RUN docker-php-ext-install \
      soap

RUN apt-get install -y libxslt1-dev
RUN docker-php-ext-install xsl \
      zip \
      sockets

RUN apt-get install -y bzip2
RUN apt-get install -y libbz2-dev
RUN docker-php-ext-install bz2

# already installed:
#      iconv \
#      mbstring \

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && ln -s $(composer config --global home) /root/composer
ENV PATH=$PATH:/root/composer/vendor/bin COMPOSER_ALLOW_SUPERUSER=1

RUN apt-get install -y npm

RUN pecl install -o -f apcu \
	&&  rm -rf /tmp/pear \
	&&  docker-php-ext-enable apcu

RUN apt-get update && apt-get install -y libmagickwand-dev --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN pecl install imagick
RUN docker-php-ext-enable imagick
RUN cd /tmp && \
	rm -rf ImageMagick-7* && \
	curl https://urban-warrior.org/ImageMagick/download/ImageMagick.tar.gz --output ImageMagick.tar.gz && \
	tar xvzf ImageMagick.tar.gz && \
	cd ImageMagick-7*/ && \
	./configure && \
	make && \
	make install && \
	ldconfig /usr/local/lib && \
	rm -rf ImageMagick-7*
RUN docker-php-ext-configure gd --with-jpeg --with-freetype
RUN docker-php-ext-install gd