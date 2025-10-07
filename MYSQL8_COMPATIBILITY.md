# MySQL 8.0 Compatibility Guide

## 🔐 Authentication Plugin Issue

### Il Problema

MySQL 8.0 usa di default il plugin di autenticazione `caching_sha2_password`, che offre maggiore sicurezza ma **non è completamente supportato dal MariaDB client** incluso in Alpine Linux.

Quando provi a connetterti senza configurazione, potresti vedere:

```
ERROR: Plugin caching_sha2_password could not be loaded
```

---

## ✅ Soluzioni

### Soluzione 1: Usare `mysql_native_password` (RACCOMANDATO per semplicità)

Configura MySQL per usare il plugin legacy ma universalmente compatibile:

```yaml
services:
  mysql:
    image: mysql:8.0
    command: --default-authentication-plugin=mysql_native_password
    environment:
      MYSQL_ROOT_PASSWORD: changeme
      MYSQL_DATABASE: myapp
```

**Pro:**
- ✅ Funziona immediatamente
- ✅ Compatibile con tutti i client
- ✅ Non richiede modifiche agli utenti esistenti

**Contro:**
- ⚠️ Plugin legacy (meno sicuro di `caching_sha2_password`)
- ⚠️ Tutti i nuovi utenti useranno questo plugin

---

### Soluzione 2: Creare Utente Dedicato con `mysql_native_password`

Mantieni `caching_sha2_password` per root e crea un utente specifico per i backup:

```yaml
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: myapp
    # Crea utente al primo avvio
    command: >
      bash -c "
      docker-entrypoint.sh mysqld &
      sleep 30 &&
      mysql -uroot -proot_password -e \"
        CREATE USER IF NOT EXISTS 'backup_user'@'%' IDENTIFIED WITH mysql_native_password BY 'backup_password';
        GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON *.* TO 'backup_user'@'%';
        FLUSH PRIVILEGES;
      \"
      wait
      "

  mysql_backup:
    depends_on:
      - mysql
    environment:
      DB_TYPE: mysql
      DB_HOST: mysql
      DB_USER: backup_user           # Utente dedicato
      DB_PASSWORD: backup_password
      DB_NAME: all
```

**Pro:**
- ✅ Root mantiene il plugin sicuro
- ✅ Utente backup ha permessi minimi (principio del least privilege)
- ✅ Migliore per ambienti di produzione

**Contro:**
- ⚠️ Setup iniziale più complesso
- ⚠️ Richiede gestione di utenti aggiuntivi

---

### Soluzione 3: Usare MySQL 5.7

Se non hai bisogno di MySQL 8.0, puoi usare MySQL 5.7 che usa `mysql_native_password` di default:

```yaml
services:
  mysql:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: changeme
      MYSQL_DATABASE: myapp
```

**Pro:**
- ✅ Nessuna configurazione necessaria
- ✅ Compatibilità totale

**Contro:**
- ⚠️ Versione più vecchia (EOL: ottobre 2023)
- ⚠️ Mancano features di MySQL 8.0

---

### Soluzione 4: Usare Base Image con MySQL Client Ufficiale

Modifica il `Dockerfile` per usare un'immagine con il MySQL client ufficiale Oracle:

```dockerfile
FROM debian:bookworm-slim

# Installa MySQL client ufficiale Oracle (supporta tutti i plugin)
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    && wget https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb \
    && dpkg -i mysql-apt-config_0.8.29-1_all.deb \
    && apt-get update \
    && apt-get install -y \
        mysql-client \
        postgresql-client \
        mongodb-clients \
        redis-tools \
        gzip \
        tar \
    && rm -rf /var/lib/apt/lists/*

# ... resto del Dockerfile
```

**Pro:**
- ✅ Supporto completo per `caching_sha2_password`
- ✅ MySQL nativo senza workarounds

**Contro:**
- ⚠️ Immagine più grande (~300MB vs ~200MB con Alpine)
- ⚠️ Richiede rebuild completo dell'immagine
- ⚠️ Debian invece di Alpine

---

## 🎯 Raccomandazioni

### Per Sviluppo/Testing
- **Soluzione 1** (`mysql_native_password` globale) - Più semplice e veloce

### Per Produzione
- **Soluzione 2** (utente dedicato) - Migliore sicurezza e controllo accessi

### Per Immagini Pubbliche
- **Soluzione 4** (MySQL client ufficiale) - Massima compatibilità senza compromessi

---

## 📚 Riferimenti

- [MySQL 8.0 Authentication Plugins](https://dev.mysql.com/doc/refman/8.0/en/authentication-plugins.html)
- [caching_sha2_password](https://dev.mysql.com/doc/refman/8.0/en/caching-sha2-pluggable-authentication.html)
- [MariaDB vs MySQL Client Compatibility](https://mariadb.com/kb/en/about-mariadb-connector-c/)

---

## 🔍 Verifica Configurazione

Testa la connessione dal container:

```bash
# Test dal container backup
docker exec -it <backup_container> sh -c 'export MYSQL_PWD="$DB_PASSWORD"; mysql -h"$DB_HOST" -u"$DB_USER" -e "SELECT VERSION();"'

# Verifica plugin autenticazione utenti
docker exec -it <mysql_container> mysql -uroot -p -e "SELECT user, host, plugin FROM mysql.user;"
```

Output atteso:
```
+---------------+-----------+-----------------------+
| user          | host      | plugin                |
+---------------+-----------+-----------------------+
| root          | %         | mysql_native_password |
| backup_user   | %         | mysql_native_password |
+---------------+-----------+-----------------------+
```
