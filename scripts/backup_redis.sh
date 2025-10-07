#!/bin/bash
set -eo pipefail

# Script per backup Redis

BACKUP_DIR="${BACKUP_DIR:-/backups}"
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT:-6379}"
DB_PASSWORD="${DB_PASSWORD}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
COMPRESS="${COMPRESS:-true}"

log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# Costruisci comando redis-cli
REDIS_CMD="redis-cli -h $DB_HOST -p $DB_PORT"
if [ -n "$DB_PASSWORD" ]; then
    REDIS_CMD="$REDIS_CMD -a $DB_PASSWORD"
fi

# Test connessione
log_info "Test connessione a Redis su $DB_HOST:$DB_PORT..."
if ! $REDIS_CMD PING >/dev/null 2>&1; then
    log_error "Impossibile connettersi al database Redis"
    exit 1
fi

# Metodo 1: BGSAVE + copia file RDB (richiede accesso al filesystem di Redis)
# Questo è un backup alternativo usando il comando SAVE per forzare snapshot
log_info "Avvio snapshot Redis..."

# Forza un save sincrono
$REDIS_CMD SAVE >/dev/null 2>&1 || {
    log_error "Errore durante il comando SAVE"
    exit 1
}

# Ottieni il percorso del file RDB (se accessibile)
# Nota: questo metodo funziona solo se il volume di Redis è montato
# Altrimenti usa redis-cli --rdb come backup alternativo

# Metodo alternativo: usa redis-cli --rdb
log_info "Creazione backup RDB..."
BACKUP_FILE="$BACKUP_DIR/redis_${TIMESTAMP}.rdb"

# Usa redis-cli per ottenere il dump
if [ -n "$DB_PASSWORD" ]; then
    redis-cli -h "$DB_HOST" -p "$DB_PORT" -a "$DB_PASSWORD" --rdb "$BACKUP_FILE" 2>/dev/null || {
        log_error "Errore durante il backup RDB"
        exit 1
    }
else
    redis-cli -h "$DB_HOST" -p "$DB_PORT" --rdb "$BACKUP_FILE" 2>/dev/null || {
        log_error "Errore durante il backup RDB"
        exit 1
    }
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
