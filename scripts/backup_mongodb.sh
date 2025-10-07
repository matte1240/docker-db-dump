#!/bin/bash
set -eo pipefail

# Script per backup MongoDB

BACKUP_DIR="${BACKUP_DIR:-/backups}"
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT:-27017}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
DB_NAME="${DB_NAME:-all}"
DB_AUTH_DB="${DB_AUTH_DB:-admin}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
COMPRESS="${COMPRESS:-true}"

log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# Costruisci stringa di connessione
if [ -n "$DB_USER" ] && [ -n "$DB_PASSWORD" ]; then
    MONGO_URI="mongodb://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/?authSource=${DB_AUTH_DB}"
    AUTH_PARAMS="--username=$DB_USER --password=$DB_PASSWORD --authenticationDatabase=$DB_AUTH_DB"
else
    MONGO_URI="mongodb://${DB_HOST}:${DB_PORT}"
    AUTH_PARAMS=""
fi

# Test connessione
log_info "Test connessione a MongoDB su $DB_HOST:$DB_PORT..."
if ! mongosh "$MONGO_URI" --quiet --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
    log_error "Impossibile connettersi al database MongoDB"
    exit 1
fi

# Esegui backup
if [ "$DB_NAME" = "all" ]; then
    log_info "Backup di tutti i database..."
    BACKUP_DIR_TEMP="$BACKUP_DIR/mongodb_all_${TIMESTAMP}"
    
    mongodump --host="$DB_HOST" --port="$DB_PORT" $AUTH_PARAMS \
        --out="$BACKUP_DIR_TEMP" \
        --gzip
    
    # Comprimi directory in un singolo archivio
    if [ "$COMPRESS" = "true" ]; then
        log_info "Creazione archivio compresso..."
        BACKUP_FILE="$BACKUP_DIR/mongodb_all_${TIMESTAMP}.tar.gz"
        tar -czf "$BACKUP_FILE" -C "$BACKUP_DIR" "mongodb_all_${TIMESTAMP}"
        rm -rf "$BACKUP_DIR_TEMP"
    else
        BACKUP_FILE="$BACKUP_DIR_TEMP"
    fi
else
    log_info "Backup database: $DB_NAME..."
    BACKUP_DIR_TEMP="$BACKUP_DIR/mongodb_${DB_NAME}_${TIMESTAMP}"
    
    mongodump --host="$DB_HOST" --port="$DB_PORT" $AUTH_PARAMS \
        --db="$DB_NAME" \
        --out="$BACKUP_DIR_TEMP" \
        --gzip
    
    # Comprimi directory in un singolo archivio
    if [ "$COMPRESS" = "true" ]; then
        log_info "Creazione archivio compresso..."
        BACKUP_FILE="$BACKUP_DIR/mongodb_${DB_NAME}_${TIMESTAMP}.tar.gz"
        tar -czf "$BACKUP_FILE" -C "$BACKUP_DIR" "mongodb_${DB_NAME}_${TIMESTAMP}"
        rm -rf "$BACKUP_DIR_TEMP"
    else
        BACKUP_FILE="$BACKUP_DIR_TEMP"
    fi
fi

# Verifica dimensione file/directory
if [ -f "$BACKUP_FILE" ]; then
    FILESIZE=$(stat -c%s "$BACKUP_FILE" 2>/dev/null || stat -f%z "$BACKUP_FILE" 2>/dev/null || echo "0")
    log_info "Backup completato: $BACKUP_FILE ($(numfmt --to=iec-i --suffix=B $FILESIZE 2>/dev/null || echo "$FILESIZE bytes"))"
else
    log_info "Backup completato: $BACKUP_FILE"
fi

exit 0
