#!/bin/bash
# Helper script per gestire il DB Backup Sidecar

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

IMAGE_NAME="${IMAGE_NAME:-db-backup-sidecar}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

print_banner() {
    cat << "EOF"
╔═══════════════════════════════════════════╗
║   DB Backup Sidecar - Management Tool    ║
╚═══════════════════════════════════════════╝
EOF
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

show_help() {
    print_banner
    cat << EOF

Uso: ./backup-helper.sh [comando]

Comandi disponibili:

  build                 Build dell'immagine Docker
  test-all             Test di tutti i database
  test-mysql           Test backup MySQL
  test-postgres        Test backup PostgreSQL
  test-mongodb         Test backup MongoDB
  test-redis           Test backup Redis
  
  backup-now [type]    Esegui un backup immediato
                       type: mysql, postgres, mongodb, redis
  
  list-backups         Mostra tutti i backup esistenti
  clean-backups        Rimuovi i backup più vecchi di X giorni
  
  restore [file]       Helper per ripristinare un backup
  
  setup-cron [type]    Configura backup schedulato
  
  validate             Valida la configurazione
  help                 Mostra questo messaggio

Esempi:
  ./backup-helper.sh build
  ./backup-helper.sh test-mysql
  ./backup-helper.sh backup-now postgres
  ./backup-helper.sh list-backups
  ./backup-helper.sh restore backups/postgres_mydb_20250107.sql.gz

EOF
}

build_image() {
    log_info "Building Docker image ${IMAGE_NAME}:${IMAGE_TAG}..."
    docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
    log_info "✅ Build completato!"
}

test_database() {
    local db_type=$1
    log_info "Testing ${db_type} backup..."
    
    mkdir -p ./test-backups/${db_type}
    
    case $db_type in
        mysql)
            docker run --rm --network host \
                -e DB_TYPE=mysql \
                -e DB_HOST=localhost \
                -e DB_USER=root \
                -e DB_PASSWORD=password \
                -v ./test-backups/mysql:/backups \
                ${IMAGE_NAME}:${IMAGE_TAG} run
            ;;
        postgres)
            docker run --rm --network host \
                -e DB_TYPE=postgres \
                -e DB_HOST=localhost \
                -e DB_USER=postgres \
                -e DB_PASSWORD=password \
                -v ./test-backups/postgres:/backups \
                ${IMAGE_NAME}:${IMAGE_TAG} run
            ;;
        mongodb)
            docker run --rm --network host \
                -e DB_TYPE=mongodb \
                -e DB_HOST=localhost \
                -e DB_USER=admin \
                -e DB_PASSWORD=password \
                -e DB_AUTH_DB=admin \
                -v ./test-backups/mongodb:/backups \
                ${IMAGE_NAME}:${IMAGE_TAG} run
            ;;
        redis)
            docker run --rm --network host \
                -e DB_TYPE=redis \
                -e DB_HOST=localhost \
                -v ./test-backups/redis:/backups \
                ${IMAGE_NAME}:${IMAGE_TAG} run
            ;;
        *)
            log_error "Tipo database non supportato: $db_type"
            return 1
            ;;
    esac
    
    log_info "✅ Test completato! Controlla ./test-backups/${db_type}"
}

test_all() {
    log_info "Running all tests..."
    for db in mysql postgres mongodb redis; do
        log_info "Testing $db..."
        test_database $db || log_warning "$db test failed"
    done
    log_info "✅ All tests completed!"
}

backup_now() {
    local db_type=$1
    
    if [ -z "$db_type" ]; then
        log_error "Specifica il tipo di database"
        echo "Uso: ./backup-helper.sh backup-now [mysql|postgres|mongodb|redis]"
        return 1
    fi
    
    if [ ! -f .env ]; then
        log_error "File .env non trovato. Copia .env.example in .env e configuralo."
        return 1
    fi
    
    log_info "Esecuzione backup ${db_type}..."
    source .env
    
    mkdir -p ./backups
    
    docker run --rm \
        --env-file .env \
        -v ./backups:/backups \
        ${IMAGE_NAME}:${IMAGE_TAG} run
    
    log_info "✅ Backup completato!"
}

list_backups() {
    log_info "Backup disponibili:"
    echo ""
    
    if [ ! -d "./backups" ]; then
        log_warning "Directory backups non trovata"
        return
    fi
    
    find ./backups -type f \( -name "*.sql.gz" -o -name "*.sql" -o -name "*.tar.gz" -o -name "*.rdb.gz" -o -name "*.rdb" \) -printf "%T+ %p %s\n" | sort -r | while read -r line; do
        date=$(echo $line | awk '{print $1}' | cut -d+ -f1)
        file=$(echo $line | awk '{print $2}')
        size=$(echo $line | awk '{print $3}')
        size_human=$(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo "${size} bytes")
        echo -e "${GREEN}${date}${NC} - ${BLUE}$(basename $file)${NC} (${size_human})"
    done
}

clean_backups() {
    echo -n "Quanti giorni di retention vuoi mantenere? [7]: "
    read days
    days=${days:-7}
    
    log_warning "Verranno eliminati i backup più vecchi di $days giorni"
    echo -n "Continuare? [y/N]: "
    read confirm
    
    if [[ $confirm == [yY] ]]; then
        log_info "Rimozione backup vecchi..."
        find ./backups -type f -mtime +$days -delete
        log_info "✅ Pulizia completata!"
    else
        log_info "Operazione annullata"
    fi
}

restore_backup() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        log_error "Specifica il file di backup"
        echo "Uso: ./backup-helper.sh restore <file>"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log_error "File non trovato: $backup_file"
        return 1
    fi
    
    log_info "File di backup: $backup_file"
    
    # Rileva il tipo di database dal nome del file
    if [[ $backup_file == *"mysql"* ]]; then
        db_type="mysql"
    elif [[ $backup_file == *"postgres"* ]]; then
        db_type="postgres"
    elif [[ $backup_file == *"mongodb"* ]]; then
        db_type="mongodb"
    elif [[ $backup_file == *"redis"* ]]; then
        db_type="redis"
    else
        log_error "Impossibile determinare il tipo di database dal nome del file"
        return 1
    fi
    
    log_info "Tipo database rilevato: $db_type"
    log_warning "ATTENZIONE: Questa operazione sovrascriverà i dati esistenti!"
    echo -n "Continuare? [y/N]: "
    read confirm
    
    if [[ $confirm != [yY] ]]; then
        log_info "Operazione annullata"
        return 0
    fi
    
    case $db_type in
        mysql)
            log_info "Comando per ripristinare MySQL:"
            echo ""
            echo "  gunzip < $backup_file | mysql -h HOST -u USER -p DATABASE"
            echo ""
            ;;
        postgres)
            log_info "Comando per ripristinare PostgreSQL:"
            echo ""
            echo "  gunzip < $backup_file | psql -h HOST -U USER DATABASE"
            echo ""
            ;;
        mongodb)
            log_info "Comandi per ripristinare MongoDB:"
            echo ""
            echo "  tar -xzf $backup_file"
            echo "  mongorestore --host HOST --username USER --password PASS \\"
            echo "    --authenticationDatabase admin EXTRACTED_DIR/"
            echo ""
            ;;
        redis)
            log_info "Comandi per ripristinare Redis:"
            echo ""
            echo "  gunzip $backup_file"
            echo "  # Ferma Redis, sostituisci dump.rdb, riavvia"
            echo ""
            ;;
    esac
}

setup_cron() {
    local db_type=$1
    
    log_info "Setup backup schedulato per $db_type"
    
    echo "Seleziona la frequenza:"
    echo "  1) Ogni 6 ore"
    echo "  2) Ogni 12 ore"
    echo "  3) Ogni giorno alle 2:00 AM"
    echo "  4) Ogni giorno alle 3:00 AM"
    echo "  5) Personalizzato"
    echo -n "Scelta [3]: "
    read choice
    choice=${choice:-3}
    
    case $choice in
        1) cron="0 */6 * * *" ;;
        2) cron="0 */12 * * *" ;;
        3) cron="0 2 * * *" ;;
        4) cron="0 3 * * *" ;;
        5)
            echo -n "Inserisci espressione cron: "
            read cron
            ;;
        *) cron="0 2 * * *" ;;
    esac
    
    log_info "Espressione cron: $cron"
    log_info "Aggiungi questa configurazione al tuo docker-compose.yml:"
    echo ""
    cat <<EOF
  ${db_type}_backup:
    image: ${IMAGE_NAME}:${IMAGE_TAG}
    environment:
      DB_TYPE: ${db_type}
      CRON_SCHEDULE: "${cron}"
      # ... altre variabili ...
    volumes:
      - ./backups:/backups
    command: ["schedule"]
EOF
    echo ""
}

validate_config() {
    log_info "Validazione configurazione..."
    
    errors=0
    
    # Verifica Dockerfile
    if [ ! -f "Dockerfile" ]; then
        log_error "Dockerfile non trovato"
        errors=$((errors + 1))
    fi
    
    # Verifica script
    for script in scripts/*.sh; do
        if ! bash -n "$script" 2>/dev/null; then
            log_error "Errore di sintassi in $script"
            errors=$((errors + 1))
        fi
    done
    
    # Verifica .env.example
    if [ ! -f ".env.example" ]; then
        log_warning ".env.example non trovato"
    fi
    
    if [ $errors -eq 0 ]; then
        log_info "✅ Validazione completata con successo!"
    else
        log_error "❌ Trovati $errors errori"
        return 1
    fi
}

# Main
case "${1:-help}" in
    build)
        build_image
        ;;
    test-all)
        test_all
        ;;
    test-mysql)
        test_database mysql
        ;;
    test-postgres)
        test_database postgres
        ;;
    test-mongodb)
        test_database mongodb
        ;;
    test-redis)
        test_database redis
        ;;
    backup-now)
        backup_now "$2"
        ;;
    list-backups)
        list_backups
        ;;
    clean-backups)
        clean_backups
        ;;
    restore)
        restore_backup "$2"
        ;;
    setup-cron)
        setup_cron "$2"
        ;;
    validate)
        validate_config
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Comando sconosciuto: $1"
        show_help
        exit 1
        ;;
esac
