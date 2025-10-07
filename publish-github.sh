#!/bin/bash
# Script per pubblicare su GitHub Container Registry

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════╗
║     📦 Publish to GitHub Container Registry (ghcr.io)             ║
╚═══════════════════════════════════════════════════════════════════╝
EOF

echo ""
echo -e "${YELLOW}Questo script pubblicherà l'immagine su GitHub Container Registry${NC}"
echo ""

# Verifica che l'immagine locale esista
if ! sudo docker images | grep -q "db-backup-sidecar.*latest"; then
    echo -e "${RED}✗ Immagine db-backup-sidecar:latest non trovata${NC}"
    echo "  Esegui prima: make build"
    exit 1
fi

echo -e "${GREEN}✓ Immagine locale trovata${NC}"
echo ""

# Configurazione
GITHUB_USER="matte1240"
IMAGE_NAME="db-backup-sidecar"
REGISTRY="ghcr.io"

echo -e "${BLUE}Configurazione:${NC}"
echo "  GitHub User: $GITHUB_USER"
echo "  Image Name:  $IMAGE_NAME"
echo "  Registry:    $REGISTRY"
echo ""

# Chiedi versione
echo -n "Versione da pubblicare (es: 1.0.0) [latest]: "
read VERSION
VERSION=${VERSION:-latest}

if [ "$VERSION" != "latest" ]; then
    # Assicurati che inizi con 'v'
    if [[ ! $VERSION =~ ^v ]]; then
        VERSION="v$VERSION"
    fi
fi

echo ""
echo -e "${YELLOW}Verrà pubblicata:${NC}"
echo "  • $REGISTRY/$GITHUB_USER/$IMAGE_NAME:latest"
if [ "$VERSION" != "latest" ]; then
    echo "  • $REGISTRY/$GITHUB_USER/$IMAGE_NAME:$VERSION"
fi
echo ""

# Chiedi token
echo -e "${YELLOW}📝 Hai bisogno di un Personal Access Token${NC}"
echo "   Crealo qui: https://github.com/settings/tokens/new"
echo "   Permessi necessari: write:packages, read:packages"
echo ""
echo -n "Inserisci il token (non verrà mostrato): "
read -s TOKEN
echo ""

if [ -z "$TOKEN" ]; then
    echo -e "${RED}✗ Token non inserito${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[1/4]${NC} Login a GitHub Container Registry..."
if echo "$TOKEN" | sudo docker login $REGISTRY -u $GITHUB_USER --password-stdin; then
    echo -e "${GREEN}✓ Login effettuato${NC}"
else
    echo -e "${RED}✗ Login fallito${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[2/4]${NC} Tagging immagine..."
sudo docker tag db-backup-sidecar:latest $REGISTRY/$GITHUB_USER/$IMAGE_NAME:latest
echo -e "${GREEN}✓ Tag latest creato${NC}"

if [ "$VERSION" != "latest" ]; then
    sudo docker tag db-backup-sidecar:latest $REGISTRY/$GITHUB_USER/$IMAGE_NAME:$VERSION
    echo -e "${GREEN}✓ Tag $VERSION creato${NC}"
fi

echo ""
echo -e "${BLUE}[3/4]${NC} Push immagine:latest..."
if sudo docker push $REGISTRY/$GITHUB_USER/$IMAGE_NAME:latest; then
    echo -e "${GREEN}✓ Push latest completato${NC}"
else
    echo -e "${RED}✗ Push fallito${NC}"
    exit 1
fi

if [ "$VERSION" != "latest" ]; then
    echo ""
    echo -e "${BLUE}[4/4]${NC} Push immagine:$VERSION..."
    if sudo docker push $REGISTRY/$GITHUB_USER/$IMAGE_NAME:$VERSION; then
        echo -e "${GREEN}✓ Push $VERSION completato${NC}"
    else
        echo -e "${RED}✗ Push fallito${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ PUBBLICAZIONE COMPLETATA!                         ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📦 Immagine pubblicata:${NC}"
echo "   $REGISTRY/$GITHUB_USER/$IMAGE_NAME:latest"
if [ "$VERSION" != "latest" ]; then
    echo "   $REGISTRY/$GITHUB_USER/$IMAGE_NAME:$VERSION"
fi
echo ""
echo -e "${BLUE}🔗 Visualizza su GitHub:${NC}"
echo "   https://github.com/$GITHUB_USER?tab=packages"
echo ""
echo -e "${BLUE}📝 Per rendere pubblica l'immagine:${NC}"
echo "   1. Vai su: https://github.com/users/$GITHUB_USER/packages/container/$IMAGE_NAME"
echo "   2. Package settings → Change visibility → Public"
echo ""
echo -e "${BLUE}🎯 Usa nei tuoi progetti:${NC}"
echo ""
echo "   services:"
echo "     backup:"
echo "       image: $REGISTRY/$GITHUB_USER/$IMAGE_NAME:latest"
echo ""
echo -e "${GREEN}Fatto! 🎉${NC}"
echo ""
