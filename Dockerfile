FROM php:7.0-fpm

MAINTAINER Samuel Laulhau <sam@lalop.co>

#####
# SYSTEM REQUIREMENT
#####
ENV PHANTOMJS phantomjs-2.1.1-linux-x86_64
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libmcrypt-dev zlib1g-dev git libgmp-dev \
        libfreetype6-dev libjpeg62-turbo-dev libpng12-dev \
        build-essential chrpath libssl-dev libxft-dev \
        libfreetype6 libfontconfig1 libfontconfig1-dev \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/ \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure gmp \
    && docker-php-ext-install iconv mcrypt mbstring pdo pdo_mysql zip gd gmp \
    && curl -o ${PHANTOMJS}.tar.bz2 -SL https://bitbucket.org/ariya/phantomjs/downloads/${PHANTOMJS}.tar.bz2 \
    && tar xvjf ${PHANTOMJS}.tar.bz2 \
    && mv ${PHANTOMJS} /usr/local/share \
    && ln -sf /usr/local/share/${PHANTOMJS}/bin/phantomjs /usr/local/bin \
    && rm -rf /var/lib/apt/lists/*

#####
# INSTALL COMPOSER
#####
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


#####
# DOWNLOAD AND INSTALL INVOICE NINJA
#####

ENV INVOICENINJA_VERSION 3.0.3

RUN curl -o invoiceninja.tar.gz -SL https://github.com/hillelcoren/invoice-ninja/archive/v${INVOICENINJA_VERSION}.tar.gz \
    && tar -xzf invoiceninja.tar.gz -C /var/www/ \
    && rm invoiceninja.tar.gz \
    && mv /var/www/invoiceninja-${INVOICENINJA_VERSION} /var/www/app \
    && chown -R www-data:www-data /var/www/app \
    && composer install --working-dir /var/www/app -o --no-dev --no-interaction --no-progress \
    && chown -R www-data:www-data /var/www/app/bootstrap/cache \
    # && echo ${INVOICENINJA_VERSION} > /var/www/app/storage/version.txt \
    && mv /var/www/app/storage /var/www/app/docker-backup-storage \
    && mv /var/www/app/public/logo /var/www/app/docker-backup-public-logo


######
# DEFAULT ENV
######
ENV DB_HOST mysql
ENV DB_DATABASE ninja
ENV APP_KEY SomeRandomString
ENV LOG errorlog
ENV APP_DEBUG 0
ENV APP_CIPHER rijndael-128
ENV SELF_UPDATER_SOURCE ''
ENV PHANTOMJS_BIN_PATH /usr/local/bin/phantomjs


#use to be mounted into nginx for exemple
VOLUME /var/www/app/public

WORKDIR /var/www/app

EXPOSE 80

COPY app-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
