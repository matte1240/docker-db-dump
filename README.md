# Docker Database Backup Sidecar

🐳 Immagine Docker universale per eseguire backup automatici di database in modalità sidecar nei tuoi stack Docker Compose.

> **🚀 Quick Start**: Esegui `./first-run.sh` per il setup guidato!

---

## 📚 Documentazione

- **[QUICKSTART.md](QUICKSTART.md)** - ⚡ Start in 5 minuti
- **[BEST_PRACTICES.md](BEST_PRACTICES.md)** - 🎯 Security e performance
- **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)** - 🔍 Struttura e componenti
- **[SUMMARY.md](SUMMARY.md)** - 📋 Riepilogo completo

---

## 🚀 Caratteristiche

- ✅ **Multi-database**: Supporta MySQL, MariaDB, PostgreSQL, MongoDB e Redis
- 🔄 **Backup schedulati**: Esegui backup automatici con cron
- 🗜️ **Compressione automatica**: Riduce lo spazio occupato dai backup
- 🧹 **Pulizia automatica**: Elimina backup vecchi in base alla retention policy
- 📝 **Logging dettagliato**: Output colorato e informativo
- 🔒 **Sicuro**: Supporta autenticazione per tutti i database
- 🎯 **Facile da usare**: Basta configurare le variabili d'ambiente

## 📦 Database Supportati

| Database | Versioni Testate | Tool Utilizzato |
|----------|-----------------|-----------------|
| MySQL | 5.7, 8.0+ | `mysqldump` |
| MariaDB | 10.x, 11.x | `mysqldump` |
| PostgreSQL | 12, 13, 14, 15, 16 | `pg_dump` / `pg_dumpall` |
| MongoDB | 5.x, 6.x, 7.x | `mongodump` |
| Redis | 6.x, 7.x | `redis-cli --rdb` |

## 🏗️ Build dell'Immagine

```bash
# Clone o naviga nella directory del progetto
cd docker_db_dump

# Build dell'immagine
docker build -t db-backup-sidecar:latest .

# Oppure con un nome personalizzato
docker build -t mio-registry/db-backup:1.0 .
```

## 🔧 Variabili d'Ambiente

### Variabili Comuni (tutti i database)

| Variabile | Obbligatoria | Default | Descrizione |
|-----------|-------------|---------|-------------|
| `DB_TYPE` | ✅ | `mysql` | Tipo di database: `mysql`, `mariadb`, `postgres`, `postgresql`, `mongodb`, `mongo`, `redis` |
| `DB_HOST` | ✅ | - | Hostname o IP del database |
| `BACKUP_DIR` | ❌ | `/backups` | Directory dove salvare i backup |
| `RETENTION_DAYS` | ❌ | `7` | Giorni di retention per i backup (0 = mai eliminare) |
| `COMPRESS` | ❌ | `true` | Abilita compressione gzip dei backup |
| `TZ` | ❌ | `Europe/Rome` | Timezone per i log e lo scheduling |

### Variabili per MySQL/MariaDB

| Variabile | Obbligatoria | Default | Descrizione |
|-----------|-------------|---------|-------------|
| `DB_PORT` | ❌ | `3306` | Porta del database |
| `DB_USER` | ✅ | - | Username database |
| `DB_PASSWORD` | ✅ | - | Password database |
| `DB_NAME` | ❌ | `all` | Nome database specifico o `all` per tutti |

### Variabili per PostgreSQL

| Variabile | Obbligatoria | Default | Descrizione |
|-----------|-------------|---------|-------------|
| `DB_PORT` | ❌ | `5432` | Porta del database |
| `DB_USER` | ✅ | - | Username database |
| `DB_PASSWORD` | ✅ | - | Password database |
| `DB_NAME` | ❌ | `all` | Nome database specifico o `all` per tutti |

### Variabili per MongoDB

| Variabile | Obbligatoria | Default | Descrizione |
|-----------|-------------|---------|-------------|
| `DB_PORT` | ❌ | `27017` | Porta del database |
| `DB_USER` | ❌ | - | Username database (se autenticazione abilitata) |
| `DB_PASSWORD` | ❌ | - | Password database (se autenticazione abilitata) |
| `DB_NAME` | ❌ | `all` | Nome database specifico o `all` per tutti |
| `DB_AUTH_DB` | ❌ | `admin` | Database di autenticazione |

### Variabili per Redis

| Variabile | Obbligatoria | Default | Descrizione |
|-----------|-------------|---------|-------------|
| `DB_PORT` | ❌ | `6379` | Porta del database |
| `DB_PASSWORD` | ❌ | - | Password Redis (se configurata) |

### Variabili per Backup Schedulati

| Variabile | Obbligatoria | Default | Descrizione |
|-----------|-------------|---------|-------------|
| `CRON_SCHEDULE` | ❌ | `0 2 * * *` | Espressione cron per lo scheduling (default: 2:00 AM ogni giorno) |

## 📖 Esempi d'Uso

### Esempio 1: Backup One-Shot di MySQL

```yaml
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: my_secret_password
      MYSQL_DATABASE: myapp
    volumes:
      - mysql_data:/var/lib/mysql

  mysql_backup:
    image: db-backup-sidecar:latest
    depends_on:
      - mysql
    environment:
      DB_TYPE: mysql
      DB_HOST: mysql
      DB_USER: root
      DB_PASSWORD: my_secret_password
      DB_NAME: all
    volumes:
      - ./backups:/backups
    command: ["run"]  # Esegue il backup una volta e termina

volumes:
  mysql_data:
```

### Esempio 2: Backup Schedulato di PostgreSQL

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: postgres_pwd
      POSTGRES_DB: myapp

  postgres_backup:
    image: db-backup-sidecar:latest
    depends_on:
      - postgres
    environment:
      DB_TYPE: postgres
      DB_HOST: postgres
      DB_USER: postgres
      DB_PASSWORD: postgres_pwd
      CRON_SCHEDULE: "0 2 * * *"  # Ogni giorno alle 2:00 AM
    volumes:
      - ./backups:/backups
    command: ["schedule"]  # Rimane in esecuzione e fa backup schedulati
```

### Esempio 3: Backup di MongoDB con Autenticazione

```yaml
services:
  mongodb:
    image: mongo:7
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: admin_pass

  mongodb_backup:
    image: db-backup-sidecar:latest
    depends_on:
      - mongodb
    environment:
      DB_TYPE: mongodb
      DB_HOST: mongodb
      DB_USER: admin
      DB_PASSWORD: admin_pass
      DB_AUTH_DB: admin
      DB_NAME: myapp  # Backup solo del database 'myapp'
      RETENTION_DAYS: 14
    volumes:
      - ./backups:/backups
    command: ["run"]
```

### Esempio 4: Backup di Redis

```yaml
services:
  redis:
    image: redis:7-alpine
    command: redis-server --requirepass my_redis_pwd

  redis_backup:
    image: db-backup-sidecar:latest
    depends_on:
      - redis
    environment:
      DB_TYPE: redis
      DB_HOST: redis
      DB_PASSWORD: my_redis_pwd
      CRON_SCHEDULE: "0 */6 * * *"  # Ogni 6 ore
    volumes:
      - ./backups:/backups
    command: ["schedule"]
```

### Esempio 5: Backup Multipli nello Stesso Stack

```yaml
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: mysql_pwd

  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: postgres_pwd

  mysql_backup:
    image: db-backup-sidecar:latest
    depends_on:
      - mysql
    environment:
      DB_TYPE: mysql
      DB_HOST: mysql
      DB_USER: root
      DB_PASSWORD: mysql_pwd
      CRON_SCHEDULE: "0 2 * * *"
    volumes:
      - ./backups/mysql:/backups
    command: ["schedule"]

  postgres_backup:
    image: db-backup-sidecar:latest
    depends_on:
      - postgres
    environment:
      DB_TYPE: postgres
      DB_HOST: postgres
      DB_USER: postgres
      DB_PASSWORD: postgres_pwd
      CRON_SCHEDULE: "0 3 * * *"
    volumes:
      - ./backups/postgres:/backups
    command: ["schedule"]
```

## 🕐 Espressioni Cron

Formato: `minuto ora giorno mese giorno_settimana`

Esempi comuni:

```bash
0 2 * * *        # Ogni giorno alle 2:00 AM
0 */6 * * *      # Ogni 6 ore
0 0 * * 0        # Ogni domenica a mezzanotte
*/30 * * * *     # Ogni 30 minuti
0 3 */2 * *      # Ogni 2 giorni alle 3:00 AM
0 4 1 * *        # Il primo giorno del mese alle 4:00 AM
```

## 📂 Formato dei File di Backup

I file di backup vengono salvati con il seguente formato:

```
MySQL/MariaDB:    mysql_[dbname]_YYYYMMDD_HHMMSS.sql.gz
PostgreSQL:       postgres_[dbname]_YYYYMMDD_HHMMSS.sql.gz
MongoDB:          mongodb_[dbname]_YYYYMMDD_HHMMSS.tar.gz
Redis:            redis_YYYYMMDD_HHMMSS.rdb.gz
```

Esempio:
```
backups/
├── mysql_myapp_20250107_020000.sql.gz
├── postgres_all_20250107_030000.sql.gz
└── mongodb_users_20250107_040000.tar.gz
```

## 🔄 Ripristino dei Backup

### MySQL/MariaDB

```bash
# Decomprimi e ripristina
gunzip < mysql_myapp_20250107_020000.sql.gz | \
  mysql -h localhost -u root -p myapp
```

### PostgreSQL

```bash
# Decomprimi e ripristina
gunzip < postgres_myapp_20250107_030000.sql.gz | \
  psql -h localhost -U postgres myapp
```

### MongoDB

```bash
# Estrai e ripristina
tar -xzf mongodb_myapp_20250107_040000.tar.gz
mongorestore --host localhost --username admin --password admin_pass \
  --authenticationDatabase admin mongodb_myapp_20250107_040000/
```

### Redis

```bash
# Decomprimi il file RDB
gunzip redis_20250107_050000.rdb.gz

# Ferma Redis, sostituisci dump.rdb e riavvia
docker compose stop redis
cp redis_20250107_050000.rdb /path/to/redis/data/dump.rdb
docker compose start redis
```

## 🐛 Troubleshooting

### I backup non vengono creati

1. Verifica i log del container:
   ```bash
   docker compose logs -f mysql_backup
   ```

2. Controlla le credenziali del database

3. Verifica la connettività di rete:
   ```bash
   docker compose exec mysql_backup ping mysql
   ```

### Errori di connessione

- Assicurati che il servizio database sia `healthy` prima che parta il backup
- Usa `depends_on` con health check se disponibile
- Verifica che i servizi siano sulla stessa rete Docker

### Lo spazio si riempie troppo velocemente

- Riduci `RETENTION_DAYS`
- Aumenta l'intervallo di backup nel `CRON_SCHEDULE`
- Mantieni `COMPRESS: "true"`

## 📄 Licenza

MIT License - Sentiti libero di usare e modificare questo progetto!

## 🤝 Contributi

I contributi sono benvenuti! Apri una issue o una pull request.

## 📞 Supporto

Per problemi o domande, apri una issue su GitHub.

---

**Nota**: Ricorda sempre di testare i tuoi backup e le procedure di ripristino in un ambiente di test prima di fare affidamento su di essi in produzione! 🔒
