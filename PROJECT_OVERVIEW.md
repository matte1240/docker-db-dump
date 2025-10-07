# Struttura del Progetto

```
docker_db_dump/
├── 📄 Dockerfile                      # Immagine Docker multi-database
├── 📄 docker-compose.example.yml      # Esempi completi per tutti i DB
├── 📄 docker-compose.quickstart.yml   # Template rapido per iniziare
├── 📄 Makefile                        # Comandi make per build e test
├── 📄 backup-helper.sh                # Script helper interattivo
├── 📄 .env.example                    # Template variabili d'ambiente
├── 📄 .gitignore                      # File da ignorare in git
├── 📄 LICENSE                         # Licenza MIT
│
├── 📖 README.md                       # Documentazione principale
├── 📖 QUICKSTART.md                   # Guida rapida 5 minuti
├── 📖 BEST_PRACTICES.md               # Best practices e security
│
├── 📁 scripts/                        # Script di backup
│   ├── backup.sh                      # Script principale
│   ├── backup_mysql.sh                # Backup MySQL/MariaDB
│   ├── backup_postgres.sh             # Backup PostgreSQL
│   ├── backup_mongodb.sh              # Backup MongoDB
│   └── backup_redis.sh                # Backup Redis
│
└── 📁 .github/
    └── workflows/
        └── docker-build.yml           # CI/CD GitHub Actions
```

## 📦 Componenti Principali

### 1. Dockerfile
Immagine Alpine Linux con tutti i client database:
- MySQL/MariaDB client
- PostgreSQL client
- MongoDB tools
- Redis CLI
- Tool di compressione

### 2. Script di Backup

#### `backup.sh` (Script Principale)
- Gestione routing per tipo database
- Logging colorato
- Gestione errori
- Pulizia automatica backup vecchi
- Supporto modalità cron

#### Script Database-Specifici
- `backup_mysql.sh` - mysqldump con opzioni ottimali
- `backup_postgres.sh` - pg_dump/pg_dumpall
- `backup_mongodb.sh` - mongodump con supporto auth
- `backup_redis.sh` - Redis RDB snapshot

### 3. Docker Compose

#### `docker-compose.example.yml`
Esempi completi con:
- MySQL con backup immediato
- PostgreSQL con backup schedulato
- MongoDB con autenticazione
- Redis con password
- MariaDB

#### `docker-compose.quickstart.yml`
Template minimal da personalizzare

### 4. Utility

#### `Makefile`
Comandi rapidi:
- `make build` - Build immagine
- `make test-mysql` - Test MySQL
- `make example-up` - Avvia esempio
- `make clean` - Pulizia

#### `backup-helper.sh`
Script interattivo per:
- Build e test
- Backup on-demand
- Lista e pulizia backup
- Setup cron
- Helper ripristino

### 5. Documentazione

#### `README.md`
- Panoramica completa
- Tutte le variabili d'ambiente
- Esempi per ogni database
- Guide ripristino
- Troubleshooting

#### `QUICKSTART.md`
- Start in 5 minuti
- 3 metodi diversi
- Cheat sheet comandi
- Configurazioni comuni

#### `BEST_PRACTICES.md`
- Strategia backup 3-2-1
- Security best practices
- Performance optimization
- Monitoring e alerting
- Disaster recovery

### 6. CI/CD

#### `.github/workflows/docker-build.yml`
GitHub Actions per:
- Lint shell scripts
- Build multi-arch (amd64/arm64)
- Test automatici
- Push su Docker Hub

## 🎯 Caratteristiche

### ✅ Multi-Database
- MySQL / MariaDB
- PostgreSQL
- MongoDB
- Redis

### ✅ Modalità di Esecuzione
- **One-shot**: Backup singolo ed esce
- **Scheduled**: Backup automatici con cron

### ✅ Configurabile
- Compressione on/off
- Retention personalizzabile
- Timezone configurabile
- Schedule cron flessibile

### ✅ Robusto
- Gestione errori completa
- Logging dettagliato
- Test connessione pre-backup
- Validazione variabili

### ✅ Sicuro
- Supporto autenticazione tutti i DB
- Utenti dedicati consigliati
- Password via env o secrets
- Permessi file restrittivi

### ✅ Efficiente
- Compressione gzip
- Pulizia automatica backup vecchi
- Opzioni ottimizzate per ogni DB
- Immagine Alpine leggera (~100MB)

## 🚀 Getting Started

### Quick Start - 3 comandi

```bash
# 1. Build
make build

# 2. Testa
make test-mysql

# 3. Usa
docker compose -f docker-compose.example.yml up -d
```

### Integrazione Esistente

Aggiungi al tuo `docker-compose.yml`:

```yaml
services:
  # Il tuo database esistente
  mysql:
    image: mysql:8.0
    # ... tua configurazione ...

  # Aggiungi solo questo
  mysql_backup:
    image: db-backup-sidecar:latest
    depends_on:
      - mysql
    environment:
      DB_TYPE: mysql
      DB_HOST: mysql
      DB_USER: root
      DB_PASSWORD: ${DB_PASSWORD}
      CRON_SCHEDULE: "0 2 * * *"
    volumes:
      - ./backups:/backups
    command: ["schedule"]
```

## 🔧 Configurazione Avanzata

### Backup Off-Site (S3)

```yaml
services:
  backup_sync:
    image: rclone/rclone
    depends_on:
      - mysql_backup
    volumes:
      - ./backups:/backups:ro
    command: >
      sync /backups s3:bucket/backups
    environment:
      RCLONE_CONFIG_S3_TYPE: s3
      RCLONE_CONFIG_S3_ACCESS_KEY_ID: ${AWS_KEY}
      RCLONE_CONFIG_S3_SECRET_ACCESS_KEY: ${AWS_SECRET}
```

### Health Check

```yaml
services:
  mysql_backup:
    # ... configurazione ...
    healthcheck:
      test: ["CMD", "test", "-f", "/backups/.last_success"]
      interval: 1h
      timeout: 10s
```

### Resource Limits

```yaml
services:
  mysql_backup:
    # ... configurazione ...
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 2G
        reservations:
          memory: 512M
```

## 📊 Formati di Backup

| Database | Formato | Dimensione Tipica | Tempo Tipico |
|----------|---------|-------------------|--------------|
| MySQL 1GB | .sql.gz | ~200-300MB | 2-5 min |
| PostgreSQL 1GB | .sql.gz | ~200-300MB | 2-5 min |
| MongoDB 1GB | .tar.gz | ~300-400MB | 3-8 min |
| Redis 1GB | .rdb.gz | ~400-600MB | 1-3 min |

## 🧪 Testing

```bash
# Test singolo database
make test-mysql

# Test tutti i database
make test-all

# Test manuale
docker run --rm \
  -e DB_TYPE=postgres \
  -e DB_HOST=myhost \
  -e DB_USER=user \
  -e DB_PASSWORD=pass \
  -v ./test-backups:/backups \
  db-backup-sidecar:latest run
```

## 📈 Roadmap

- [ ] Supporto SQLite
- [ ] Supporto Microsoft SQL Server
- [ ] Backup incrementali
- [ ] Webhook notifiche
- [ ] Metrics exporter (Prometheus)
- [ ] Web UI per gestione
- [ ] Backup encryption nativo
- [ ] S3 storage integrato

## 🤝 Contributing

1. Fork il progetto
2. Crea feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push al branch (`git push origin feature/amazing`)
5. Apri Pull Request

## 📝 Licenza

MIT License - vedi [LICENSE](LICENSE)

## 🙏 Ringraziamenti

- Alpine Linux per l'immagine base
- Community Docker
- Tutti i contributors

## 📞 Supporto

- 📧 Email: support@example.com
- 💬 GitHub Issues: [github.com/user/repo/issues](https://github.com)
- 📖 Docs: [Read the docs](https://example.com)

---

**Made with ❤️ for the DevOps community**
