# 🔧 v1.0.1 - MySQL 8.0 Compatibility Fix

**Release Date**: October 7, 2025  
**Type**: Bug Fix / Compatibility Update

---

## 🐛 Bug Fixed

### MySQL 8.0 Authentication Plugin Incompatibility

**Issue**: The backup container failed to connect to MySQL 8.0 databases due to authentication plugin mismatch between `caching_sha2_password` (MySQL 8.0 default) and `mariadb-client` (Alpine Linux).

**Error Message**:
```
[ERROR] Impossibile connettersi al database MySQL/MariaDB
Plugin caching_sha2_password could not be loaded
```

---

## ✅ Changes

### 1. Fixed MySQL Backup Script (`scripts/backup_mysql.sh`)

**Before**:
```bash
mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;"
```

**After**:
```bash
export MYSQL_PWD="$DB_PASSWORD"
mysql -h"$DB_HOST" -u"$DB_USER" -e "SELECT 1;"
```

- Uses `MYSQL_PWD` environment variable (more secure and compatible)
- Removes password from command line arguments
- Eliminates shell parsing issues with special characters in passwords

---

### 2. Updated Docker Compose Examples

**Added healthcheck to MySQL service**:
```yaml
mysql:
  healthcheck:
    test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-pchangeme"]
    interval: 5s
    timeout: 3s
    retries: 10
    start_period: 30s
```

**Added condition to backup service**:
```yaml
mysql_backup:
  depends_on:
    mysql:
      condition: service_healthy  # Wait for MySQL to be ready
```

**Configured MySQL authentication plugin**:
```yaml
mysql:
  command: --default-authentication-plugin=mysql_native_password
```

This ensures compatibility with Alpine's `mariadb-client` while maintaining security.

---

### 3. New Documentation: `MYSQL8_COMPATIBILITY.md`

Comprehensive guide covering:
- ✅ **4 different solutions** to the compatibility issue
- ✅ **Pro/Cons analysis** for each approach
- ✅ **Production recommendations**
- ✅ **Security considerations**
- ✅ **Verification commands**

**Solutions documented**:
1. Use `mysql_native_password` globally (simplest)
2. Create dedicated backup user (most secure)
3. Use MySQL 5.7 (backwards compatibility)
4. Use official MySQL client (full compatibility)

---

### 4. Updated Dockerfile

Explicit package naming and documentation:
```dockerfile
# Note: Alpine usa mariadb-client che è compatibile con MySQL 5.x-8.x
# Per MySQL 8.0 con caching_sha2_password, configurare MySQL con 
# --default-authentication-plugin=mysql_native_password
RUN apk add --no-cache \
    bash \
    curl \
    mariadb-client \
    postgresql-client \
    mongodb-tools \
    redis \
    gzip \
    tar \
    tzdata
```

---

## 🧪 Testing

All tests passed successfully:

- ✅ **Build**: Image builds without errors (~198MB)
- ✅ **MySQL 8.0.43**: Connection successful with `mysql_native_password`
- ✅ **MySQL 5.7**: Backward compatible (no changes needed)
- ✅ **MariaDB**: Fully compatible
- ✅ **Backup creation**: SQL dumps created and compressed successfully
- ✅ **Healthcheck**: Container waits for MySQL to be ready
- ✅ **Data integrity**: Backup content verified

**Test Environment**:
- MySQL 8.0.43 official image
- Alpine Linux 3.19
- MariaDB client 10.11.14

**Sample backup created**:
```bash
mysql_all_20251007_225219.sql.gz (923KB)
- Includes all databases (myapp, mysql, sys, etc.)
- Gzip compressed
- Verified restore capability
```

---

## 📋 Migration Guide

### If you're using v1.0.0:

**Option 1: Update docker-compose.yml** (Recommended)

Add to your MySQL service:
```yaml
command: --default-authentication-plugin=mysql_native_password
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
  interval: 10s
  timeout: 5s
  retries: 5
```

Update your backup service:
```yaml
depends_on:
  mysql:
    condition: service_healthy
```

**Option 2: Create dedicated backup user**

```sql
CREATE USER 'backup'@'%' IDENTIFIED WITH mysql_native_password BY 'secure_password';
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON *.* TO 'backup'@'%';
FLUSH PRIVILEGES;
```

Then use `backup` user in backup container environment.

---

## 🔗 Links

- **Repository**: https://github.com/matte1240/docker-db-dump
- **Docker Image**: `ghcr.io/matte1240/db-backup-sidecar:v1.0.1`
- **Full Documentation**: [MYSQL8_COMPATIBILITY.md](MYSQL8_COMPATIBILITY.md)
- **Previous Release**: [v1.0.0](https://github.com/matte1240/docker-db-dump/releases/tag/v1.0.0)

---

## 📦 Installation

### Pull the updated image:

```bash
docker pull ghcr.io/matte1240/db-backup-sidecar:v1.0.1
```

### Or use in docker-compose.yml:

```yaml
services:
  mysql_backup:
    image: ghcr.io/matte1240/db-backup-sidecar:v1.0.1
    # ... rest of configuration
```

---

## 🙏 Credits

Thanks to the community for reporting the MySQL 8.0 compatibility issue and helping test the fix.

---

## 📝 Full Changelog

**Commits**:
- `1fbd9a1` - Fix MySQL 8.0 compatibility (Oct 7, 2025)

**Files Changed**:
- `Dockerfile` - Updated comments and explicit package naming
- `scripts/backup_mysql.sh` - Fixed authentication method
- `docker-compose.example.yml` - Added healthcheck and depends_on
- `docker-compose.quickstart.yml` - Added healthcheck and documentation
- `MYSQL8_COMPATIBILITY.md` - **NEW** - Complete compatibility guide

**Lines Changed**: +241 / -25

---

**Upgrade now for seamless MySQL 8.0 support! 🚀**

```bash
docker pull ghcr.io/matte1240/db-backup-sidecar:v1.0.1
```
