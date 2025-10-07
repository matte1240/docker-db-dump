#!/bin/bash
# Script di primo avvio - Configura e testa il progetto

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║        🐳 DB Backup Sidecar - First Run Setup        ║
║                                                       ║
║   Backup automatico multi-database per Docker        ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
EOF

echo ""
echo -e "${BLUE}Questo script ti guiderà nel setup iniziale del progetto.${NC}"
echo ""

# Step 1: Check Docker
echo -e "${YELLOW}[1/5]${NC} Verifica Docker..."
if ! command -v docker &> /dev/null; then
    echo -e "  ❌ Docker non trovato. Installa Docker prima di continuare."
    echo -e "     Visita: https://docs.docker.com/get-docker/"
    exit 1
fi
echo -e "  ✅ Docker trovato: $(docker --version)"

# Step 2: Build Image
echo ""
echo -e "${YELLOW}[2/5]${NC} Build dell'immagine Docker..."
echo -n "  Vuoi fare il build ora? [S/n]: "
read -r response
if [[ ! $response =~ ^[Nn]$ ]]; then
    echo "  Building..."
    docker build -t db-backup-sidecar:latest .
    echo -e "  ✅ Build completato!"
else
    echo "  ⏭️  Build saltato"
fi

# Step 3: Setup .env
echo ""
echo -e "${YELLOW}[3/5]${NC} Configurazione variabili d'ambiente..."
if [ -f .env ]; then
    echo -e "  ⚠️  File .env già esistente"
    echo -n "  Vuoi sovrascriverlo? [s/N]: "
    read -r response
    if [[ $response =~ ^[Ss]$ ]]; then
        cp .env.example .env
        echo -e "  ✅ File .env creato da template"
        echo -e "  📝 Modifica .env con le tue credenziali!"
    fi
else
    cp .env.example .env
    echo -e "  ✅ File .env creato da template"
    echo -e "  📝 Ricorda di modificare .env con le tue credenziali!"
fi

# Step 4: Create backup directory
echo ""
echo -e "${YELLOW}[4/5]${NC} Creazione directory backup..."
mkdir -p backups
echo -e "  ✅ Directory ./backups creata"

# Step 5: Choose test
echo ""
echo -e "${YELLOW}[5/5]${NC} Test iniziale..."
echo "  Quale database vuoi testare?"
echo "    1) MySQL"
echo "    2) PostgreSQL"
echo "    3) MongoDB"
echo "    4) Redis"
echo "    5) Salta test"
echo -n "  Scelta [5]: "
read -r choice

case ${choice:-5} in
    1)
        echo "  Per testare MySQL, devi avere un'istanza MySQL in esecuzione."
        echo "  Avvia con: docker run -d --name test-mysql -e MYSQL_ROOT_PASSWORD=password mysql:8.0"
        echo "  Poi esegui: make test-mysql"
        ;;
    2)
        echo "  Per testare PostgreSQL, devi avere un'istanza PostgreSQL in esecuzione."
        echo "  Avvia con: docker run -d --name test-postgres -e POSTGRES_PASSWORD=password postgres:16"
        echo "  Poi esegui: make test-postgres"
        ;;
    3)
        echo "  Per testare MongoDB, devi avere un'istanza MongoDB in esecuzione."
        echo "  Avvia con: docker run -d --name test-mongo mongo:7"
        echo "  Poi esegui: make test-mongodb"
        ;;
    4)
        echo "  Per testare Redis, devi avere un'istanza Redis in esecuzione."
        echo "  Avvia con: docker run -d --name test-redis redis:7-alpine"
        echo "  Poi esegui: make test-redis"
        ;;
    *)
        echo "  ⏭️  Test saltato"
        ;;
esac

# Summary
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║               ✅ Setup Completato!                    ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Prossimi passi:${NC}"
echo ""
echo "  1️⃣  Leggi la documentazione:"
echo "     📖 README.md - Documentazione completa"
echo "     🚀 QUICKSTART.md - Start rapido in 5 minuti"
echo "     🎯 BEST_PRACTICES.md - Best practices"
echo ""
echo "  2️⃣  Configura il tuo database:"
echo "     📝 Modifica .env con le tue credenziali"
echo "     🐳 Usa docker-compose.example.yml come riferimento"
echo ""
echo "  3️⃣  Comandi utili:"
echo "     make build          - Build immagine"
echo "     make test-mysql     - Test MySQL"
echo "     make example-up     - Avvia esempi"
echo "     make help           - Vedi tutti i comandi"
echo ""
echo "  4️⃣  Script helper:"
echo "     ./backup-helper.sh help           - Aiuto"
echo "     ./backup-helper.sh backup-now     - Backup immediato"
echo "     ./backup-helper.sh list-backups   - Lista backup"
echo ""
echo -e "${GREEN}Buon backup! 🚀${NC}"
echo ""
