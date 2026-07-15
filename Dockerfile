# Multi-stage build for optimized image size
FROM php:8.2-apache AS base

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    netcat-traditional \
    && docker-php-ext-install mysqli pdo pdo_mysql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache modules for better performance and security
RUN a2enmod rewrite headers

# Set working directory
WORKDIR /var/www/html/

# Copy application files (excluding unnecessary files via .dockerignore)
COPY php-app/ /var/www/html/

# Set proper permissions for Apache
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Security: Run as non-root user
USER www-data

# Health check for container monitoring
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

EXPOSE 80

# Use exec form for better signal handling
CMD ["apache2-foreground"]
