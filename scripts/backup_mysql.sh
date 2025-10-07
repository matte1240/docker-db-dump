#!/bin/bash
set -eo pipefail

# Script per backup MySQL/MariaDB

BACKUP_DIR="${BACKUP_DIR:-/backups}"
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
DB_NAME="${DB_NAME:-all}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
COMPRESS="${COMPRESS:-true}"

log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# Test connessione
log_info "Test connessione a MySQL/MariaDB su $DB_HOST:$DB_PORT..."
export MYSQL_PWD="$DB_PASSWORD"
if ! mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -e "SELECT 1;" >/dev/null 2>&1; then
    log_error "Impossibile connettersi al database MySQL/MariaDB"
    exit 1
fi

# Esegui backup
if [ "$DB_NAME" = "all" ]; then
    log_info "Backup di tutti i database..."
    BACKUP_FILE="$BACKUP_DIR/mysql_all_${TIMESTAMP}.sql"
    
    mysqldump -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
        --all-databases \
        --single-transaction \
        --quick \
        --lock-tables=false \
        --routines \
        --triggers \
        --events > "$BACKUP_FILE"
else
    log_info "Backup database: $DB_NAME..."
    BACKUP_FILE="$BACKUP_DIR/mysql_${DB_NAME}_${TIMESTAMP}.sql"
    
    mysqldump -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
        --databases "$DB_NAME" \
        --single-transaction \
        --quick \
        --lock-tables=false \
        --routines \
        --triggers \
        --events > "$BACKUP_FILE"
fi

# Comprimi se richiesto
if [ "$COMPRESS" = "true" ]; then
    log_info "Compressione backup..."
    gzip "$BACKUP_FILE"
    BACKUP_FILE="${BACKUP_FILE}.gz"
fi

# Verifica dimensione file
FILESIZE=$(stat -c%s "$BACKUP_FILE" 2>/dev/null || stat -f%z "$BACKUP_FILE" 2>/dev/null || echo "0")
log_info "Backup completato: $BACKUP_FILE ($(numfmt --to=iec-i --suffix=B $FILESIZE 2>/dev/null || echo "$FILESIZE bytes"))"

exit 0
