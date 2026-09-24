FROM php:8.3-cli

# Cài các package cần thiết để build PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-install \
        pdo_mysql \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Cài Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy Composer files trước để tận dụng Docker cache
COPY composer.json composer.lock ./

# Cài PHP dependencies
# Chưa chạy Laravel scripts vì source chưa được copy
RUN composer install \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts

# Copy source Laravel
COPY . .

# Chạy lại Composer scripts sau khi source Laravel đã tồn tại
RUN composer dump-autoload --optimize

# Laravel storage
RUN php artisan storage:link || true

EXPOSE 8000


CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]