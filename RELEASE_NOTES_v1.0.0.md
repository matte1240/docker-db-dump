# 🎉 v1.0.0 - Initial Public Release

## 📦 Docker Database Backup Sidecar

Universal Docker backup solution for multiple database types with sidecar pattern support.

---

## ✨ Features

### 🗄️ **Supported Databases**
- ✅ **MySQL** / MariaDB
- ✅ **PostgreSQL**
- ✅ **MongoDB**
- ✅ **Redis**

### 🚀 **Core Features**
- ✅ **Automatic Scheduling** - Cron-based backup scheduling
- ✅ **Compression** - Automatic gzip compression
- ✅ **Retention Policies** - Configurable backup retention
- ✅ **Sidecar Pattern** - Easy Docker Compose integration
- ✅ **One-shot & Scheduled** - Run once or continuous scheduling
- ✅ **Error Handling** - Robust error management and logging
- ✅ **Multi-database** - Backup all databases or specific ones

### 📚 **Documentation**
- ✅ Complete README with examples
- ✅ Quick Start guide (5 minutes)
- ✅ Best Practices guide
- ✅ Docker Compose examples for all databases
- ✅ Troubleshooting section

### 🔧 **Developer Tools**
- ✅ Makefile with common commands
- ✅ Helper scripts for easy usage
- ✅ GitHub Actions CI/CD
- ✅ Multi-arch support ready (amd64/arm64)

---

## 🐳 Quick Start

### Using Docker

```bash
docker pull ghcr.io/matte1240/db-backup-sidecar:v1.0.0

docker run --rm \
  -e DB_TYPE=mysql \
  -e DB_HOST=mysql \
  -e DB_USER=root \
  -e DB_PASSWORD=password \
  -v ./backups:/backups \
  ghcr.io/matte1240/db-backup-sidecar:v1.0.0 run
```

### Using Docker Compose

```yaml
services:
  mysql_backup:
    image: ghcr.io/matte1240/db-backup-sidecar:v1.0.0
    environment:
      DB_TYPE: mysql
      DB_HOST: mysql
      DB_USER: root
      DB_PASSWORD: ${DB_PASSWORD}
      CRON_SCHEDULE: "0 2 * * *"  # Daily at 2 AM
    volumes:
      - ./backups:/backups
    command: ["schedule"]
```

---

## 📥 Installation

### Option 1: Use Pre-built Image (Recommended)

```bash
docker pull ghcr.io/matte1240/db-backup-sidecar:v1.0.0
```

### Option 2: Build from Source

```bash
git clone https://github.com/matte1240/docker-db-dump.git
cd docker-db-dump
docker build -t db-backup-sidecar:v1.0.0 .
```

---

## 📖 Documentation

- **[README.md](https://github.com/matte1240/docker-db-dump/blob/v1.0.0/README.md)** - Complete documentation
- **[QUICKSTART.md](https://github.com/matte1240/docker-db-dump/blob/v1.0.0/QUICKSTART.md)** - 5-minute quick start
- **[BEST_PRACTICES.md](https://github.com/matte1240/docker-db-dump/blob/v1.0.0/BEST_PRACTICES.md)** - Security & performance
- **[PROJECT_OVERVIEW.md](https://github.com/matte1240/docker-db-dump/blob/v1.0.0/PROJECT_OVERVIEW.md)** - Technical overview

---

## 🔧 Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DB_TYPE` | ✅ | `mysql` | Database type: mysql, postgres, mongodb, redis |
| `DB_HOST` | ✅ | - | Database hostname |
| `DB_USER` | ⚠️ | - | Database user (required for most DBs) |
| `DB_PASSWORD` | ⚠️ | - | Database password (required for most DBs) |
| `CRON_SCHEDULE` | ❌ | `0 2 * * *` | Cron schedule for backups |
| `RETENTION_DAYS` | ❌ | `7` | Days to keep backups |
| `COMPRESS` | ❌ | `true` | Enable gzip compression |

---

## 📊 What's Included

- **Dockerfile** - Multi-database Alpine-based image
- **Backup Scripts** - MySQL, PostgreSQL, MongoDB, Redis
- **Docker Compose Examples** - Ready-to-use templates
- **Helper Scripts** - Easy publish and management
- **Makefile** - Common commands
- **GitHub Actions** - CI/CD workflow
- **Complete Documentation** - Guides and best practices

---

## 🎯 Use Cases

- **Production Backups** - Scheduled automatic backups
- **Development** - Local database backup/restore
- **Disaster Recovery** - Point-in-time recovery
- **Multi-environment** - Same solution for all databases
- **Docker Compose Stacks** - Sidecar pattern integration

---

## 🔒 Security

- ✅ Credentials via environment variables
- ✅ Docker secrets support
- ✅ Read-only database user recommended
- ✅ Backup encryption compatible
- ✅ Best practices documented

---

## 📈 Statistics

- **Image Size**: ~198MB (Alpine-based)
- **Supported Databases**: 4 (MySQL, PostgreSQL, MongoDB, Redis)
- **Documentation Files**: 5
- **Example Configs**: 2
- **Helper Scripts**: 3

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

---

## 🙏 Acknowledgments

Built with ❤️ for the DevOps community

- Alpine Linux for the base image
- All database client tools maintainers
- Docker and container ecosystem

---

## 🔗 Links

- **Repository**: https://github.com/matte1240/docker-db-dump
- **Docker Image**: https://github.com/matte1240/packages/container/package/db-backup-sidecar
- **Issues**: https://github.com/matte1240/docker-db-dump/issues
- **Documentation**: https://github.com/matte1240/docker-db-dump#readme

---

## 📝 Checksums

- **Image SHA**: `a24cc601f9ab7563e91fa28da8e66064d38f618db0927c61d6bbf1b10f96f7c2`
- **Tag**: `v1.0.0`
- **Git Commit**: `77aad95`

---

**Installation**: `docker pull ghcr.io/matte1240/db-backup-sidecar:v1.0.0`

**Quick Test**:
```bash
docker run --rm ghcr.io/matte1240/db-backup-sidecar:v1.0.0 --help
```

Enjoy automated database backups! 🚀
