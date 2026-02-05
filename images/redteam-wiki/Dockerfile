# CYROID Red Team Lab - Internal Wiki (DokuWiki)
# Contains sensitive internal documentation
#
# Credentials:
# - admin:Admin2024! (full access)
# - employee:Welcome123 (read access)
#
# Build: docker build -t cyroid/redteam-wiki:latest .

FROM php:8.2-apache

# Install required extensions
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install gd \
    && rm -rf /var/lib/apt/lists/*

# Download and install DokuWiki
RUN curl -L https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz | tar -xz -C /var/www/html --strip-components=1 \
    && chown -R www-data:www-data /var/www/html

# Copy pre-configured wiki content
COPY wiki-data/ /var/www/html/data/
RUN chown -R www-data:www-data /var/www/html/data

EXPOSE 80
