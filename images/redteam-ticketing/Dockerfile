# CYROID Red Team Lab - Ticketing System
# Simple ticket system with exposed internal information
#
# Build: docker build -t cyroid/redteam-ticketing:latest .
# Size: ~150MB (PHP/Apache base, minimal extensions)

FROM php:8.2-apache

RUN mkdir -p /var/www/html/tickets \
    && chown -R www-data:www-data /var/www/html

COPY index.php /var/www/html/
COPY tickets.json /var/www/html/tickets/

EXPOSE 80
