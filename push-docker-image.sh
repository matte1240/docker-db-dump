#!/bin/bash
# Script helper per pubblicare l'immagine Docker v1.0.1 su GitHub Container Registry

set -e

echo "=== Docker Image Push Helper - v1.0.1 ==="
echo ""

# Colori
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verifica che l'immagine locale esista
if ! docker images | grep -q "ghcr.io/matte1240/db-backup-sidecar.*v1.0.1"; then
    echo -e "${RED}✗ Immagine ghcr.io/matte1240/db-backup-sidecar:v1.0.1 non trovata${NC}"
    echo ""
    echo "Esegui prima:"
    echo "  docker build -t ghcr.io/matte1240/db-backup-sidecar:v1.0.1 ."
    echo "  docker tag ghcr.io/matte1240/db-backup-sidecar:v1.0.1 ghcr.io/matte1240/db-backup-sidecar:latest"
    exit 1
fi

echo -e "${GREEN}✓ Immagine locale trovata${NC}"
echo ""

# Mostra info immagine
echo -e "${BLUE}Informazioni immagine:${NC}"
docker images | grep -E "(REPOSITORY|ghcr.io/matte1240/db-backup-sidecar)" | head -5
echo ""

# Verifica login
echo -e "${BLUE}Step 1: Verifica login GitHub Container Registry${NC}"
echo ""
echo "Hai bisogno di un Personal Access Token con scope 'write:packages'"
echo "Crea il token su: https://github.com/settings/tokens"
echo ""
echo -e "${YELLOW}Per fare il login:${NC}"
echo "  export GITHUB_TOKEN=ghp_your_token_here"
echo "  echo \$GITHUB_TOKEN | docker login ghcr.io -u matte1240 --password-stdin"
echo ""

read -p "Hai già fatto il login? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Esegui il login prima di continuare."
    exit 1
fi

echo ""
echo -e "${BLUE}Step 2: Push immagine v1.0.1${NC}"
echo ""
read -p "Vuoi pushare ghcr.io/matte1240/db-backup-sidecar:v1.0.1? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Pushing v1.0.1..."
    docker push ghcr.io/matte1240/db-backup-sidecar:v1.0.1
    echo -e "${GREEN}✓ Push v1.0.1 completato${NC}"
else
    echo "Push v1.0.1 saltato"
fi

echo ""
echo -e "${BLUE}Step 3: Push immagine latest${NC}"
echo ""
read -p "Vuoi pushare ghcr.io/matte1240/db-backup-sidecar:latest? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Pushing latest..."
    docker push ghcr.io/matte1240/db-backup-sidecar:latest
    echo -e "${GREEN}✓ Push latest completato${NC}"
else
    echo "Push latest saltato"
fi

echo ""
echo -e "${GREEN}=== Pubblicazione completata! ===${NC}"
echo ""
echo "Le immagini sono ora disponibili su:"
echo "  - https://github.com/matte1240/packages/container/package/db-backup-sidecar"
echo ""
echo "Per usarle:"
echo "  docker pull ghcr.io/matte1240/db-backup-sidecar:v1.0.1"
echo "  docker pull ghcr.io/matte1240/db-backup-sidecar:latest"
echo ""
echo -e "${YELLOW}Ricorda di rendere il package pubblico se necessario:${NC}"
echo "  https://github.com/users/matte1240/packages/container/db-backup-sidecar/settings"
echo ""
