FROM php:5.6.37-apache
 
# PHP extensions and necessary packages
RUN apt-get update && apt-get install -y \
cron \
libfreetype6-dev \
libjpeg62-turbo-dev \
libmcrypt-dev \
libpng-dev \
sendmail sendmail-bin \
unzip \
libxslt1-dev

RUN docker-php-ext-install -j$(nproc) exif \
&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
&& docker-php-ext-install -j$(nproc) gd \
&& docker-php-ext-install -j$(nproc) iconv \
&& docker-php-ext-install -j$(nproc) mbstring \
&& docker-php-ext-install -j$(nproc) mysqli \
&& docker-php-ext-install -j$(nproc) opcache \
&& docker-php-ext-install -j$(nproc) pdo \
&& docker-php-ext-install -j$(nproc) pdo_mysql \
&& docker-php-ext-install -j$(nproc) zip \
&& docker-php-ext-install -j$(nproc) xsl \
&& docker-php-ext-install -j$(nproc) calendar \
&& docker-php-ext-install -j$(nproc) mcrypt \
&& rm -rf /var/lib/apt/lists/*
 
# User folder
 
RUN groupadd -r --gid 2483 dolphin \
&& useradd -r --uid 2483 -g dolphin dolphin
 
RUN chown dolphin:dolphin /var/www/html /var/www
 
# Unzip package
 
USER dolphin
 
WORKDIR /var/www/html
 
ENV DOLPHIN_VERSION 7.3.5

RUN curl -fSL "https://github.com/boonex/dolphin.pro/releases/download/${DOLPHIN_VERSION}/Dolphin-v.${DOLPHIN_VERSION}.zip" -o dolphin.zip \
&& unzip -o dolphin.zip \
&& rm dolphin.zip \
&& mv Dolphin-v.${DOLPHIN_VERSION}/* . \
&& mv Dolphin-v.${DOLPHIN_VERSION}/.htaccess . \
&& rm -rf "Dolphin-v.${DOLPHIN_VERSION}"
 
RUN chmod -R 777 /var/www/html/
 
# Apache configuration
 
USER root
 
RUN echo "memory_limit=192M \n\
post_max_size=100M \n\
upload_max_filesize=100M \n\
error_log=/var/www/php_error.log \n\
error_reporting=E_ALL & ~E_NOTICE & ~E_DEPRECATED & ~E_STRICT \n\
display_errors=Off \n\
log_errors=On \n\
sendmail_path=/usr/sbin/sendmail -t -i \n\
date.timezone=UTC" > /var/www/php.ini && chown dolphin:dolphin /var/www/php.ini
 
RUN touch /var/www/php_error.log \
&& chown dolphin:dolphin /var/www/php_error.log \
&& chmod 666 /var/www/php_error.log
 
RUN echo "<VirtualHost *:80> \n\
DocumentRoot /var/www/html \n\
PHPINIDir /var/www \n\
ErrorLog /var/www/error.log \n\
CustomLog /var/www/access.log combined \n\
</VirtualHost>" > /etc/apache2/sites-enabled/dolphin.conf
 
RUN a2enmod rewrite expires
 
# Crontab
 
RUN echo "* * * * * php -c /var/www /var/www/html/periodic/cron.php" > /var/www/crontab
 
RUN chown dolphin:dolphin /var/www/crontab \
&& crontab -u dolphin /var/www/crontab
 
# Expose port
 
VOLUME /var/www

EXPOSE 80
