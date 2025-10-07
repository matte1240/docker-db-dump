FROM alpine:3.19

# Installa i client per tutti i database principali
RUN apk add --no-cache \
    bash \
    curl \
    mysql-client \
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
