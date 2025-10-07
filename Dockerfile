FROM alpine:3.19

# Installa i client per tutti i database principali
# Note: Alpine usa mariadb-client che è compatibile con MySQL 5.x-8.x
# Per MySQL 8.0 con caching_sha2_password, configurare MySQL con --default-authentication-plugin=mysql_native_password
RUN apk add --no-cache \
    bash \
    curl \
    mariadb-client \
    postgresql-client \
    mongodb-tools \
    redis \
    gzip \
    tar \
    tzdata \
    && rm -rf /var/cache/apk/*

# Crea directory per i backup e gli script
RUN mkdir -p /backups /scripts

# Copia gli script di backup
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Imposta la timezone di default
ENV TZ=Europe/Rome

# Volume per i backup
VOLUME ["/backups"]

# Script principale come entrypoint
ENTRYPOINT ["/scripts/backup.sh"]
