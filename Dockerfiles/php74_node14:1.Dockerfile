FROM focal-base:1
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
  apt-get install -y curl software-properties-common && \
  add-apt-repository -y ppa:ondrej/php && \
  curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
  apt-get update && \
  apt-get install -y php7.4-cli php7.4-curl php7.4-gd php7.4-intl \
    php7.4-mbstring php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-zip \
    nodejs && \
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
  php composer-setup.php --install-dir=/usr/local/bin/ --filename=composer && \
  rm -rf /var/lib/apt/lists/*

