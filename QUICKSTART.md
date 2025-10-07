# 🚀 Guida Rapida - Start in 5 Minuti

## Metodo 1: Usando il Makefile (Raccomandato)

```bash
# 1. Build dell'immagine
make build

# 2. Testa con MySQL
make test-mysql

# 3. Avvia esempio completo
make example-up

# 4. Vedi i log
make example-logs

# 5. Ferma tutto
make example-down
```

## Metodo 2: Usando lo script helper

```bash
# 1. Build dell'immagine
./backup-helper.sh build

# 2. Copia e configura .env
cp .env.example .env
nano .env  # Modifica con le tue credenziali

# 3. Esegui un backup
./backup-helper.sh backup-now mysql

# 4. Lista backup
./backup-helper.sh list-backups
```

## Metodo 3: Docker Compose manuale

### Passo 1: Build

```bash
docker build -t db-backup-sidecar:latest .
```

### Passo 2: Crea docker-compose.yml

```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: mypassword
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
      DB_PASSWORD: mypassword
      DB_NAME: all
    volumes:
      - ./backups:/backups
    command: ["run"]

volumes:
  mysql_data:
```

### Passo 3: Avvia

```bash
docker compose up -d
```

### Passo 4: Verifica backup

```bash
ls -lh backups/
```

## 📋 Cheat Sheet Comandi

| Azione | Comando |
|--------|---------|
| Build immagine | `make build` o `docker build -t db-backup-sidecar .` |
| Test MySQL | `make test-mysql` |
| Test PostgreSQL | `make test-postgres` |
| Backup immediato | `docker compose run mysql_backup run` |
| Vedere log | `docker compose logs -f mysql_backup` |
| Lista backup | `ls -lh backups/` |
| Ripristino MySQL | `gunzip < backup.sql.gz \| mysql -h host -u user -p db` |
| Ripristino PostgreSQL | `gunzip < backup.sql.gz \| psql -h host -U user db` |

## 🔄 Configurazione Backup Schedulati

Cambia il command da `run` a `schedule`:

```yaml
services:
  mysql_backup:
    image: db-backup-sidecar:latest
    environment:
      DB_TYPE: mysql
      DB_HOST: mysql
      DB_USER: root
      DB_PASSWORD: mypassword
      CRON_SCHEDULE: "0 2 * * *"  # Ogni giorno alle 2 AM
    volumes:
      - ./backups:/backups
    command: ["schedule"]  # ← Cambia qui
```

## 🎯 Configurazioni Comuni

### Backup giornaliero con retention 7 giorni

```yaml
environment:
  CRON_SCHEDULE: "0 2 * * *"
  RETENTION_DAYS: 7
```

### Backup ogni 6 ore con retention 3 giorni

```yaml
environment:
  CRON_SCHEDULE: "0 */6 * * *"
  RETENTION_DAYS: 3
```

### Backup solo un database specifico

```yaml
environment:
  DB_NAME: mydatabase  # invece di 'all'
```

### Backup senza compressione

```yaml
environment:
  COMPRESS: "false"
```

## 🆘 Troubleshooting Veloce

**Problema**: Backup non viene creato
```bash
# Controlla i log
docker compose logs mysql_backup

# Verifica connessione al DB
docker compose exec mysql_backup ping mysql
```

**Problema**: Errore di connessione al database
```bash
# Verifica che il DB sia avviato
docker compose ps

# Testa credenziali
docker compose exec mysql mysql -u root -p
```

**Problema**: Spazio disco pieno
```bash
# Riduci retention
environment:
  RETENTION_DAYS: 3

# Riavvia il container
docker compose restart mysql_backup
```

## 📖 Prossimi Passi

1. Leggi il [README.md](README.md) completo per tutte le opzioni
2. Consulta [BEST_PRACTICES.md](BEST_PRACTICES.md) per consigli su produzione
3. Personalizza gli script in `scripts/` se necessario
4. Configura backup off-site (S3, etc)
5. Implementa monitoraggio e alerting

## ✅ Checklist Pre-Produzione

- [ ] Testato ripristino backup
- [ ] Configurata retention policy
- [ ] Impostato backup schedulato
- [ ] Backup off-site attivo
- [ ] Monitoring configurato
- [ ] Documentato processo di ripristino
- [ ] Team formato

## 💡 Tips

- Usa sempre `depends_on` per assicurarti che il DB sia pronto
- Monta i backup su un volume esterno/NAS
- Testa i ripristini regolarmente
- Usa utenti dedicati per i backup
- Monitora lo spazio disco
- Cripta i backup sensibili
- Documenta il processo di disaster recovery

---

**Hai bisogno di aiuto?** Apri una issue su GitHub o consulta la documentazione completa!
