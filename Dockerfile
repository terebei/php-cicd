FROM php:PHP_VERSION-apache 

RUN apt-get update && apt-get install -y \
                vim \
                libfreetype6-dev \
                libjpeg62-turbo-dev \
                libpng-dev \
        && docker-php-ext-configure gd --with-freetype --with-jpeg 
RUN /usr/local/bin/docker-php-ext-install -j$(nproc) gd mysqli pdo pdo_mysql 

COPY . /var/www/html

#RUN curl -L   https://github.com/elastic/apm-agent-php/releases/download/v1.6.2/apm-agent-php_1.6.2_all.deb -o /tmp/apm.deb
#RUN dpkg -i /tmp/apm.deb

#COPY conf.d/elastic-apm-custom.ini /opt/elastic/apm-agent-php/etc/
COPY conf.d/security.ini //usr/local/etc/php/conf.d
COPY conf.d/security.conf /etc/apache2/conf-enabled/

RUN a2enmod rewrite \
   && a2enmod headers
RUN service apache2 restart

# Intégration de New Relic
ARG NEW_RELIC_AGENT_VERSION
ARG NEW_RELIC_LICENSE_KEY
 
RUN curl -L https://download.newrelic.com/php_agent/archive/${NEW_RELIC_AGENT_VERSION}/newrelic-php5-${NEW_RELIC_AGENT_VERSION}-linux.tar.gz | tar -C /tmp -zx \
    && export NR_INSTALL_USE_CP_NOT_LN=1 \
    && export NR_INSTALL_SILENT=1 \
    && /tmp/newrelic-php5-${NEW_RELIC_AGENT_VERSION}-linux/newrelic-install install \
    && rm -rf /tmp/newrelic-php5-* /tmp/nrinstall*
    
    
RUN sed -i -e "s/REPLACE_WITH_REAL_KEY/${NEW_RELIC_LICENSE_KEY}/" \
    -e '$anewrelic.daemon.address="@newrelic"' \
    $(php -r "echo(PHP_CONFIG_FILE_SCAN_DIR);")/newrelic.ini
    
 RUN sed -i -e "s/newrelic.appname.*/newrelic.appname=\"APP_NAME\"/"  \
     $(php -r "echo(PHP_CONFIG_FILE_SCAN_DIR);")/newrelic.ini

