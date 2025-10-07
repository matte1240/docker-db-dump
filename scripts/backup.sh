#!/bin/bash
set -eo pipefail

# Script principale per il backup dei database
# Supporta: MySQL/MariaDB, PostgreSQL, MongoDB, Redis

# Configurazione
BACKUP_DIR="${BACKUP_DIR:-/backups}"
DB_TYPE="${DB_TYPE:-mysql}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS="${RETENTION_DAYS:-7}"
COMPRESS="${COMPRESS:-true}"

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Verifica variabili obbligatorie
check_required_vars() {
    local missing_vars=()
    
    case "$DB_TYPE" in
        mysql|mariadb)
            [ -z "$DB_HOST" ] && missing_vars+=("DB_HOST")
            [ -z "$DB_USER" ] && missing_vars+=("DB_USER")
            [ -z "$DB_PASSWORD" ] && missing_vars+=("DB_PASSWORD")
            ;;
        postgres|postgresql)
            [ -z "$DB_HOST" ] && missing_vars+=("DB_HOST")
            [ -z "$DB_USER" ] && missing_vars+=("DB_USER")
            [ -z "$DB_PASSWORD" ] && missing_vars+=("DB_PASSWORD")
            ;;
        mongodb|mongo)
            [ -z "$DB_HOST" ] && missing_vars+=("DB_HOST")
            ;;
        redis)
            [ -z "$DB_HOST" ] && missing_vars+=("DB_HOST")
            ;;
        *)
            log_error "Tipo database non supportato: $DB_TYPE"
            log_info "Tipi supportati: mysql, mariadb, postgres, postgresql, mongodb, mongo, redis"
            exit 1
            ;;
    esac
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        log_error "Variabili obbligatorie mancanti: ${missing_vars[*]}"
        exit 1
    fi
}

# Pulizia backup vecchi
cleanup_old_backups() {
    if [ "$RETENTION_DAYS" -gt 0 ]; then
        log_info "Pulizia backup più vecchi di $RETENTION_DAYS giorni..."
        find "$BACKUP_DIR" -type f -name "*.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
        find "$BACKUP_DIR" -type f -name "*.sql" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
        find "$BACKUP_DIR" -type f -name "*.dump" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
        find "$BACKUP_DIR" -type f -name "*.rdb" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    fi
}

# Esegui backup in base al tipo di database
perform_backup() {
    case "$DB_TYPE" in
        mysql|mariadb)
            log_info "Avvio backup MySQL/MariaDB..."
            /scripts/backup_mysql.sh
            ;;
        postgres|postgresql)
            log_info "Avvio backup PostgreSQL..."
            /scripts/backup_postgres.sh
            ;;
        mongodb|mongo)
            log_info "Avvio backup MongoDB..."
            /scripts/backup_mongodb.sh
            ;;
        redis)
            log_info "Avvio backup Redis..."
            /scripts/backup_redis.sh
            ;;
    esac
}

# Funzione principale
main() {
    log_info "=== Avvio processo di backup ==="
    log_info "Tipo database: $DB_TYPE"
    log_info "Directory backup: $BACKUP_DIR"
    
    # Crea directory backup se non esiste
    mkdir -p "$BACKUP_DIR"
    
    # Verifica variabili
    check_required_vars
    
    # Esegui backup
    perform_backup
    
    # Pulizia backup vecchi
    cleanup_old_backups
    
    log_info "=== Backup completato con successo ==="
}

# Se viene passato "schedule" come parametro, esegui in modalità cron
if [ "$1" = "schedule" ]; then
    CRON_SCHEDULE="${CRON_SCHEDULE:-0 2 * * *}"
    log_info "Modalità schedule attivata: $CRON_SCHEDULE"
    
    # Crea file crontab
    echo "$CRON_SCHEDULE /scripts/backup.sh run >> /var/log/backup.log 2>&1" > /tmp/crontab.txt
    crontab /tmp/crontab.txt
    
    # Avvia crond in foreground
    crond -f -l 2
else
    # Esegui backup immediatamente
    main
fi
