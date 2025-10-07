# Scripts Directory

Questa directory contiene tutti gli script bash per eseguire i backup dei database.

## File

### `backup.sh` (Script Principale)
Lo script principale che:
- Controlla le variabili d'ambiente richieste
- Routing verso lo script specifico per tipo di database
- Gestisce il cleanup dei backup vecchi
- Supporta modalità cron con scheduling

**Variabili d'ambiente:**
- `DB_TYPE` - Tipo di database (obbligatorio)
- `DB_HOST` - Host del database (obbligatorio)
- `BACKUP_DIR` - Directory per i backup (default: /backups)
- `RETENTION_DAYS` - Giorni di retention (default: 7)
- `COMPRESS` - Abilita compressione (default: true)
- `CRON_SCHEDULE` - Schedule cron (modalità schedule)

**Modalità:**
```bash
# One-shot backup
/scripts/backup.sh run

# Scheduled backup
/scripts/backup.sh schedule
```

### `backup_mysql.sh`
Backup per MySQL e MariaDB usando `mysqldump`.

**Opzioni mysqldump usate:**
- `--all-databases` - Backup di tutti i database
- `--single-transaction` - Consistency senza lock
- `--quick` - Recupera righe una alla volta (memory efficient)
- `--lock-tables=false` - Non locka le tabelle
- `--routines` - Include stored procedures
- `--triggers` - Include triggers
- `--events` - Include eventi schedulati

**Variabili specifiche:**
- `DB_PORT` - Porta (default: 3306)
- `DB_USER` - Username (obbligatorio)
- `DB_PASSWORD` - Password (obbligatorio)
- `DB_NAME` - Nome database o 'all' (default: all)

### `backup_postgres.sh`
Backup per PostgreSQL usando `pg_dump` o `pg_dumpall`.

**Opzioni usate:**
- `--clean` - Include DROP statements
- `--if-exists` - Safe drop statements
- `--create` - Include CREATE DATABASE (pg_dump)

**Variabili specifiche:**
- `DB_PORT` - Porta (default: 5432)
- `DB_USER` - Username (obbligatorio)
- `DB_PASSWORD` - Password (obbligatorio via PGPASSWORD)
- `DB_NAME` - Nome database o 'all' (default: all)

### `backup_mongodb.sh`
Backup per MongoDB usando `mongodump`.

**Opzioni usate:**
- `--gzip` - Compressione nativa
- `--out` - Directory output
- `--db` - Database specifico (opzionale)

**Variabili specifiche:**
- `DB_PORT` - Porta (default: 27017)
- `DB_USER` - Username (opzionale)
- `DB_PASSWORD` - Password (opzionale)
- `DB_NAME` - Nome database o 'all' (default: all)
- `DB_AUTH_DB` - Database di autenticazione (default: admin)

**Nota:** Il backup viene creato come directory e poi archiviato in tar.gz

### `backup_redis.sh`
Backup per Redis usando `redis-cli --rdb`.

**Metodo:**
1. Esegue `SAVE` per forzare snapshot
2. Usa `redis-cli --rdb` per scaricare l'RDB file

**Variabili specifiche:**
- `DB_PORT` - Porta (default: 6379)
- `DB_PASSWORD` - Password (opzionale)

## Logging

Tutti gli script usano funzioni di logging comuni:
- `log_info()` - Messaggi informativi (verde)
- `log_error()` - Messaggi di errore (rosso)
- `log_warning()` - Warning (giallo)

Formato log: `[LEVEL] YYYY-MM-DD HH:MM:SS - messaggio`

## Gestione Errori

Tutti gli script usano:
```bash
set -eo pipefail
```

Questo significa:
- `-e` - Exit se un comando fallisce
- `-o pipefail` - Exit se qualsiasi comando in una pipe fallisce

## Compressione

I file vengono compressi con `gzip` se `COMPRESS=true`:
- MySQL: `.sql` → `.sql.gz`
- PostgreSQL: `.sql` → `.sql.gz`
- MongoDB: directory → `.tar.gz`
- Redis: `.rdb` → `.rdb.gz`

Rapporto compressione tipico: 3:1 a 5:1

## Naming Convention

I file di backup seguono questo pattern:
```
{dbtype}_{dbname}_{YYYYMMDD_HHMMSS}.{ext}

Esempi:
mysql_myapp_20250107_142530.sql.gz
postgres_all_20250107_142530.sql.gz
mongodb_users_20250107_142530.tar.gz
redis_20250107_142530.rdb.gz
```

## Test Connessione

Ogni script testa la connessione al database prima di eseguire il backup:
- MySQL: `mysql -e "SELECT 1;"`
- PostgreSQL: `psql -c "SELECT 1;"`
- MongoDB: `mongosh --eval "db.adminCommand('ping')"`
- Redis: `redis-cli PING`

## Personalizzazione

Per personalizzare gli script:

1. Copia lo script che vuoi modificare
2. Modifica le opzioni del comando di backup
3. Aggiorna il Dockerfile per copiare la tua versione

Esempio:
```dockerfile
COPY scripts/backup.sh /scripts/
COPY custom/backup_mysql.sh /scripts/  # La tua versione
```

## Debugging

Per debuggare uno script:

```bash
# Aggiungi debug output
set -x  # All'inizio dello script

# Oppure esegui con bash -x
bash -x /scripts/backup_mysql.sh

# Oppure usa docker
docker run --rm -it db-backup-sidecar:latest /bin/bash
# Poi esegui manualmente lo script
```

## Performance Tips

### MySQL/MariaDB
- Usa `--single-transaction` per InnoDB (evita lock)
- Usa `--quick` per database grandi
- Considera `mydumper` per database molto grandi (>100GB)

### PostgreSQL
- Usa formato custom (`-Fc`) per database grandi
- Usa jobs paralleli (`-j N`) per tabelle multiple
- Considera `pg_basebackup` per database molto grandi

### MongoDB
- `mongodump` è già parallelo per collection
- Usa `--gzip` per risparmiare banda
- Considera `mongodump --oplog` per point-in-time recovery

### Redis
- `BGSAVE` è non-bloccante ma usa più memoria
- `SAVE` è bloccante ma usa meno memoria
- Considera snapshot periodici + AOF per durability

## Security

⚠️ **IMPORTANTE:**
- Non loggare mai le password
- Usa `set +x` prima di comandi con password
- Le password sono passate via variabili d'ambiente, non argomenti
- Per PostgreSQL usa `PGPASSWORD`
- Per MySQL/MariaDB la password è nel comando (inevitabile)

## Exit Codes

- `0` - Successo
- `1` - Errore generico
- Exit codes sono propagati al container

## Contribuire

Per aggiungere supporto a un nuovo database:

1. Crea `backup_newdb.sh`
2. Segui la struttura degli script esistenti
3. Aggiungi gestione errori con `set -eo pipefail`
4. Implementa test connessione
5. Aggiungi logging con funzioni standard
6. Aggiorna `backup.sh` per includere il nuovo tipo
7. Aggiorna il Dockerfile per installare il client
8. Aggiorna la documentazione

Esempio template:
```bash
#!/bin/bash
set -eo pipefail

# Script per backup NEWDB

BACKUP_DIR="${BACKUP_DIR:-/backups}"
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT:-1234}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
COMPRESS="${COMPRESS:-true}"

log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# Test connessione
log_info "Test connessione..."
# ... test code ...

# Esegui backup
log_info "Backup in corso..."
BACKUP_FILE="$BACKUP_DIR/newdb_${TIMESTAMP}.dump"
# ... backup command ...

# Comprimi
if [ "$COMPRESS" = "true" ]; then
    gzip "$BACKUP_FILE"
    BACKUP_FILE="${BACKUP_FILE}.gz"
fi

log_info "Backup completato: $BACKUP_FILE"
exit 0
```

## License

MIT License - Vedi LICENSE nel root del progetto
