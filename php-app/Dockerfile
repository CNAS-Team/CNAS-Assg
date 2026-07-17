FROM php:8.2-apache

# Install mysqli extension and curl for healthcheck, then clean up
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && docker-php-ext-install mysqli \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache rewrite module
RUN a2enmod rewrite headers

# Copy application source
COPY . /var/www/html/

# Set correct ownership for www-data (UID 33 on Debian-based images)
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

EXPOSE 80

# Run Apache as www-data (non-root, UID 33)
USER www-data

CMD ["apache2-foreground"]
