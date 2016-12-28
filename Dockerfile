FROM ubuntu:16.04
MAINTAINER Matti M <matti10@protonmail.com>

# Have desired nextcloud in the same place as your Dockerfile like nextcloud.conf 

# ENV DEBIAN_FRONTEND noninteractive

# Install apache, PHP, and supplimentary programs. openssh-server, curl, and lynx-cur are for debugging the container.
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install \
   nano apache2 apache2-utils php7.0 php7.0-mysql php7.0-gd php7.0-json php7.0-curl php7.0-zip php7.0-xml php7.0-mbstring libapache2-mod-php7.0 curl lynx-cur

# Enable apache mods.
RUN a2enmod php7.0
RUN a2enmod rewrite

# Update the PHP.ini file, enable <? ?> tags and quieten logging.
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/7.0/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php/7.0/apache2/php.ini

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Install MariaDB and set default root password and create database nextcloud

RUN DEBIAN_FRONTEND=noninteractive echo 'mariadb-server mariadb-server/root_password  password water555m' | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive echo 'mariadb-server mariadb-server/root_password_again password water555m' | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive apt-get install mariadb-server -y

ADD init_db.sh /tmp/init_db.sh
RUN chmod +x /tmp/init_db.sh
RUN /tmp/init_db.sh

# Add nextcloud to /var/www/html
ADD /nextcloud/ /var/www/html/nextcloud/
RUN chown www-data:www-data /var/www/html/ -R

# Expose apache.
EXPOSE 80
EXPOSE 443

# Copy this repo into place. (ignore this is my testing)
ADD www /var/www/html

# Update the default apache site with the config we created.
ADD nextcloud.conf /etc/apache2/sites-enabled/000-default.conf

# Remove APT files
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Making sure apache2 and mariadb service runs 
# ENTRYPOINT service apache2 start && bash
# ENTRYPOINT service mysql restart && bash
ADD service.sh /tmp/service.sh
RUN chmod +x /tmp/service.sh
ENTRYPOINT /tmp/service.sh

# By default start up apache in the foreground, override with /bin/bash for interative.
CMD /usr/sbin/apache2ctl -D FOREGROUND

