#!/bin/bash
set -eo pipefail

# Script per backup PostgreSQL

BACKUP_DIR="${BACKUP_DIR:-/backups}"
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
DB_NAME="${DB_NAME:-all}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
COMPRESS="${COMPRESS:-true}"

# PostgreSQL usa variabili d'ambiente per la password
export PGPASSWORD="$DB_PASSWORD"

log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# Test connessione
log_info "Test connessione a PostgreSQL su $DB_HOST:$DB_PORT..."
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
    log_error "Impossibile connettersi al database PostgreSQL"
    exit 1
fi

# Esegui backup
if [ "$DB_NAME" = "all" ]; then
    log_info "Backup di tutti i database..."
    BACKUP_FILE="$BACKUP_DIR/postgres_all_${TIMESTAMP}.sql"
    
    pg_dumpall -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
        --clean \
        --if-exists > "$BACKUP_FILE"
else
    log_info "Backup database: $DB_NAME..."
    BACKUP_FILE="$BACKUP_DIR/postgres_${DB_NAME}_${TIMESTAMP}.sql"
    
    pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        --clean \
        --if-exists \
        --create > "$BACKUP_FILE"
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

# Pulisci variabile password
unset PGPASSWORD

exit 0
