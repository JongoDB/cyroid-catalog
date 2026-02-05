# CYROID Red Team Lab - Ticketing System
# Simple ticket system with exposed internal information
#
# Credentials:
# - admin:Admin2024! (admin access)
# - helpdesk:Help2024! (agent access)
#
# Build: docker build -t cyroid/redteam-ticketing:latest .

FROM php:8.2-apache

# Install extensions
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libzip-dev \
    && docker-php-ext-install gd zip pdo pdo_mysql \
    && rm -rf /var/lib/apt/lists/*

# Create a simple ticketing page
RUN mkdir -p /var/www/html/tickets

COPY index.php /var/www/html/
COPY tickets.json /var/www/html/tickets/

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
