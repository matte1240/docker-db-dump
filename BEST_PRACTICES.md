# Best Practices per i Backup Database

## 📋 Indice

- [Strategia di Backup](#strategia-di-backup)
- [Sicurezza](#sicurezza)
- [Performance](#performance)
- [Monitoraggio](#monitoraggio)
- [Disaster Recovery](#disaster-recovery)

## Strategia di Backup

### Regola 3-2-1

Segui sempre la regola **3-2-1** per i backup:
- **3** copie dei tuoi dati
- **2** tipi di media diversi
- **1** copia off-site (fuori sede)

### Frequenza dei Backup

| Tipo di Ambiente | Frequenza Consigliata | Retention |
|-----------------|----------------------|-----------|
| Produzione Critica | Ogni 6-12 ore | 30 giorni |
| Produzione Standard | Ogni 24 ore | 14 giorni |
| Staging | Ogni 24 ore | 7 giorni |
| Sviluppo | Settimanale | 7 giorni |

### Esempio di Configurazione per Produzione

```yaml
services:
  db_backup:
    image: db-backup-sidecar:latest
    environment:
      DB_TYPE: postgres
      DB_HOST: postgres
      DB_USER: backup_user  # Usa un utente dedicato
      DB_PASSWORD: ${DB_BACKUP_PASSWORD}  # Usa secrets
      CRON_SCHEDULE: "0 */6 * * *"  # Ogni 6 ore
      RETENTION_DAYS: 30
      COMPRESS: "true"
    volumes:
      - /mnt/backup-storage:/backups  # Storage dedicato
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 2G
```

## Sicurezza

### 1. Usa Utenti Dedicati per i Backup

**MySQL/MariaDB:**
```sql
CREATE USER 'backup_user'@'%' IDENTIFIED BY 'secure_password';
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON *.* TO 'backup_user'@'%';
FLUSH PRIVILEGES;
```

**PostgreSQL:**
```sql
CREATE ROLE backup_user WITH LOGIN PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE mydb TO backup_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO backup_user;
```

**MongoDB:**
```javascript
use admin
db.createUser({
  user: "backup_user",
  pwd: "secure_password",
  roles: [
    { role: "backup", db: "admin" },
    { role: "read", db: "config" }
  ]
})
```

### 2. Proteggi le Credenziali

**Usa Docker Secrets (Docker Swarm):**
```yaml
services:
  db_backup:
    image: db-backup-sidecar:latest
    secrets:
      - db_password
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password

secrets:
  db_password:
    external: true
```

**Usa .env Files:**
```bash
# Non committare mai il file .env nel repository!
echo ".env" >> .gitignore

# Usa un file .env per le credenziali
cat > .env <<EOF
DB_PASSWORD=your_secure_password
EOF

chmod 600 .env
```

### 3. Cripta i Backup

Aggiungi uno step di crittografia:

```yaml
services:
  db_backup:
    image: db-backup-sidecar:latest
    # ... configurazione normale ...
    
  backup_encrypt:
    image: alpine:latest
    depends_on:
      - db_backup
    volumes:
      - ./backups:/backups
      - ./backups-encrypted:/encrypted
    entrypoint: |
      sh -c "
      apk add --no-cache gnupg
      while true; do
        find /backups -name '*.gz' -mmin -10 | while read file; do
          if [ ! -f /encrypted/\$(basename \$file).gpg ]; then
            gpg --batch --yes --passphrase \$GPG_PASSPHRASE \
                --symmetric --cipher-algo AES256 \
                --output /encrypted/\$(basename \$file).gpg \$file
          fi
        done
        sleep 300
      done
      "
    environment:
      GPG_PASSPHRASE: ${GPG_PASSPHRASE}
```

### 4. Limita l'Accesso ai Backup

```bash
# Imposta permessi restrittivi sulla directory dei backup
chmod 700 backups/
chown backup-user:backup-group backups/

# In Docker, usa un volume con permessi limitati
docker volume create --driver local \
  --opt type=none \
  --opt device=/secure/backup/location \
  --opt o=bind,uid=1000,gid=1000,mode=700 \
  backup_volume
```

## Performance

### 1. Ottimizza il Timing dei Backup

- Schedula i backup durante i periodi di basso traffico
- Evita backup simultanei di database multipli
- Usa backup incrementali quando possibile

### 2. Configurazione per Database Grandi

**MySQL - Backup Paralleli:**
```bash
# Modifica backup_mysql.sh per usare mydumper (più veloce)
mydumper -h $DB_HOST -u $DB_USER -p $DB_PASSWORD \
  --threads=4 \
  --compress \
  --outputdir $BACKUP_DIR
```

**PostgreSQL - Formato Custom:**
```bash
# Più veloce per database grandi
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME \
  -Fc \  # Formato custom
  -Z 6 \  # Livello compressione
  -j 4 \  # Job paralleli
  -f $BACKUP_FILE
```

### 3. Monitoraggio delle Risorse

```yaml
services:
  db_backup:
    image: db-backup-sidecar:latest
    deploy:
      resources:
        limits:
          cpus: '2'      # Limita CPU usage
          memory: 4G     # Limita memoria
        reservations:
          cpus: '0.5'
          memory: 1G
```

## Monitoraggio

### 1. Health Checks

```yaml
services:
  db_backup:
    image: db-backup-sidecar:latest
    healthcheck:
      test: ["CMD", "test", "-f", "/backups/latest.success"]
      interval: 1h
      timeout: 10s
      retries: 3
```

### 2. Notifiche via Webhook

Aggiungi al file `backup.sh`:

```bash
# Alla fine della funzione main()
send_notification() {
    local status=$1
    local message=$2
    
    if [ -n "$WEBHOOK_URL" ]; then
        curl -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"status\": \"$status\", \"message\": \"$message\", \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
    fi
}

# Usa dopo il backup
if [ $? -eq 0 ]; then
    send_notification "success" "Backup completato"
else
    send_notification "error" "Backup fallito"
fi
```

### 3. Logging Strutturato

```yaml
services:
  db_backup:
    image: db-backup-sidecar:latest
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
        labels: "backup,database"
```

### 4. Monitoraggio con Prometheus

Crea un exporter per esporre metriche:

```bash
# Aggiungi a backup.sh
export_metrics() {
    cat > /backups/metrics.prom <<EOF
backup_last_success_timestamp $(date +%s)
backup_size_bytes $(stat -f%z "$BACKUP_FILE")
backup_duration_seconds $DURATION
EOF
}
```

## Disaster Recovery

### 1. Testa Regolarmente i Backup

```bash
#!/bin/bash
# test-restore.sh

# Avvia un database temporaneo
docker run -d --name test-db \
    -e POSTGRES_PASSWORD=test \
    postgres:16

# Attendi che sia pronto
sleep 10

# Ripristina il backup più recente
LATEST_BACKUP=$(ls -t backups/postgres_*.sql.gz | head -1)
gunzip < $LATEST_BACKUP | docker exec -i test-db \
    psql -U postgres

# Verifica l'integrità
docker exec test-db psql -U postgres -c "SELECT COUNT(*) FROM users;"

# Cleanup
docker rm -f test-db
```

### 2. Documentazione del Processo di Ripristino

Crea un runbook:

```markdown
# RUNBOOK: Ripristino Database di Emergenza

## PostgreSQL

1. Stop applicazione:
   docker compose stop app

2. Backup database corrente (precauzione):
   docker compose exec postgres pg_dump -U postgres mydb > emergency_backup.sql

3. Ripristino:
   gunzip < backups/postgres_mydb_YYYYMMDD.sql.gz | \
     docker compose exec -T postgres psql -U postgres

4. Verifica:
   docker compose exec postgres psql -U postgres -d mydb -c "\dt"

5. Restart applicazione:
   docker compose start app

## Tempo stimato: 15-30 minuti
## Downtime previsto: 20-40 minuti
```

### 3. Backup Off-Site Automatico

```yaml
services:
  backup_sync:
    image: rclone/rclone:latest
    depends_on:
      - db_backup
    volumes:
      - ./backups:/backups:ro
      - ./rclone-config:/config/rclone
    command: >
      sync /backups remote:backup-bucket
      --config /config/rclone/rclone.conf
      --transfers 4
      --checkers 8
    environment:
      - RCLONE_CONFIG_REMOTE_TYPE=s3
      - RCLONE_CONFIG_REMOTE_ACCESS_KEY_ID=${AWS_ACCESS_KEY}
      - RCLONE_CONFIG_REMOTE_SECRET_ACCESS_KEY=${AWS_SECRET_KEY}
```

### 4. Retention Policy Avanzata

```bash
# Script per retention intelligente
#!/bin/bash
# retention-policy.sh

BACKUP_DIR="/backups"
DAILY_RETENTION=7    # 7 giorni
WEEKLY_RETENTION=4   # 4 settimane
MONTHLY_RETENTION=12 # 12 mesi

# Mantieni backup giornalieri degli ultimi 7 giorni
find "$BACKUP_DIR" -name "*.gz" -mtime +$DAILY_RETENTION -mtime -8 -delete

# Mantieni un backup per settimana (domenica) degli ultimi 4 settimane
# Implementazione custom...

# Mantieni un backup per mese (primo del mese) degli ultimi 12 mesi
# Implementazione custom...
```

## Checklist Pre-Produzione

- [ ] Backup schedulati configurati
- [ ] Test di ripristino eseguiti con successo
- [ ] Monitoring e alerting attivi
- [ ] Backup off-site configurato
- [ ] Documentazione aggiornata
- [ ] Team formato sulla procedura di ripristino
- [ ] Credenziali sicure e gestite correttamente
- [ ] Retention policy implementata
- [ ] Health checks attivi
- [ ] Runbook di disaster recovery pronto

## Risorse Utili

- [PostgreSQL Backup Best Practices](https://www.postgresql.org/docs/current/backup.html)
- [MySQL Backup and Recovery](https://dev.mysql.com/doc/refman/8.0/en/backup-and-recovery.html)
- [MongoDB Backup Methods](https://www.mongodb.com/docs/manual/core/backups/)
- [Redis Persistence](https://redis.io/docs/management/persistence/)
