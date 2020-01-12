FROM ubuntu:18.04
MAINTAINER Daniel Frota

# Definir variáveis de ambiente da aplicação laravel
ENV DEBIAN_FRONTEND=noninteractive \
    APP_ENV=local \
    # DEBUG false pois usuário não precisa/pode ver erros
    APP_DEBUG=true \
    APP_KEY=base64:ae1SwpKt8ZaSotdVstp9zCLyeA95W0JM+sQhnKZAaMI= \
    APP_TIMEZONE=UTC \
    LOG_CHANNEL=stack \
    LOG_SLACK_WEBHOOK_URL= \
    # Selecionamos o driver do MySQL
    DB_CONNECTION=mysql \
    DB_HOST=mysql_db \
    DB_PORT=3306 \
    DB_DATABASE=bdsipe_dev \
    DB_USERNAME=root \
    DB_PASSWORD=sejus2020 \
    CACHE_DRIVER=file \
    QUEUE_DRIVER=sync

# Instalando o APACHE, o PHP e suas extenções, o nodejs e o npm
RUN apt update -y && apt install -y \
    software-properties-common \
    apache2 && add-apt-repository ppa:ondrej/php -y && apt-cache pkgnames | grep php7.2 \
    && apt install -y tzdata curl supervisor git unzip libpq-dev nano php \
    php-bcmath php-bz2 php-intl php-gd php-mbstring php-mysql php-zip php-fpm php-xml \
    nodejs npm git

# Instalando o Composer e o laravel
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Configurando o Apache
# Aqui copiamos nosso arquivo de configuração para dentro do container
COPY ./config/apache2.conf /etc/apache2/apache2.conf
COPY ./config/sites-enabled/* /etc/apache2/sites-enabled/
COPY ./config/sites-available/* /etc/apache2/sites-available/

# Arquivo de configuração do supervisor
#COPY supervisord.conf /etc/supervisord.conf

# Configurando os virtualhosts, desabilitando a configuração padrão, Habilitando a reescrita do apache e restartando o serviço
RUN a2ensite sipe.conf sipe-admin.conf && chown -R www-data:www-data /var/www/sipe && chown -R www-data:www-data /var/www/sipe-admin \
    && a2dissite 000-default.conf && a2enmod rewrite && systemctl reload apache2

# Copiar os arquivos da aplicação
COPY ./app/* /var/www/

# Dando permissões para a pasta do projeto
RUN chmod -R 755 /var/www && apt update -y && apt upgrade -y \
    && chown -R $USER ~/.composer/ \
    && composer global require laravel/installer

# Selecionar o diretório da aplicação
WORKDIR /var/www/

EXPOSE 80 443

# Iniciando o servidor apache em primeiro plano para que o container permaneça ativo
CMD ["apachectl", "-D", "FOREGROUND"]


