#!/bin/bash
# Script helper per pubblicare su GitHub e Docker registries

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     📤 GitHub & Docker Registry Publisher            ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Verifica Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}✗ Repository Git non inizializzato${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Repository Git trovato${NC}"
echo ""

# Menu principale
echo "Cosa vuoi fare?"
echo ""
echo "  1) 🔗 Collega repository GitHub remoto"
echo "  2) 📤 Push su GitHub"
echo "  3) 🐳 Pubblica immagine su Docker Hub"
echo "  4) 📦 Pubblica immagine su GitHub Container Registry"
echo "  5) 🏷️  Crea tag versione"
echo "  6) ℹ️  Mostra informazioni repository"
echo "  7) ❌ Esci"
echo ""
echo -n "Scelta [1-7]: "
read choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}═══ Collega Repository GitHub ═══${NC}"
        echo ""
        echo -n "Username GitHub: "
        read username
        echo -n "Nome repository [docker-db-backup-sidecar]: "
        read repo_name
        repo_name=${repo_name:-docker-db-backup-sidecar}
        
        echo ""
        echo "Scegli protocollo:"
        echo "  1) HTTPS (più facile)"
        echo "  2) SSH (richiede chiavi configurate)"
        echo -n "Scelta [1]: "
        read protocol
        protocol=${protocol:-1}
        
        if [ "$protocol" = "1" ]; then
            remote_url="https://github.com/${username}/${repo_name}.git"
        else
            remote_url="git@github.com:${username}/${repo_name}.git"
        fi
        
        git remote add origin "$remote_url" 2>/dev/null || git remote set-url origin "$remote_url"
        echo ""
        echo -e "${GREEN}✓ Remote 'origin' configurato: $remote_url${NC}"
        echo ""
        echo "Esegui ora:"
        echo "  git push -u origin main"
        ;;
        
    2)
        echo ""
        echo -e "${YELLOW}═══ Push su GitHub ═══${NC}"
        echo ""
        
        if ! git remote get-url origin >/dev/null 2>&1; then
            echo -e "${RED}✗ Remote 'origin' non configurato${NC}"
            echo "Esegui prima l'opzione 1"
            exit 1
        fi
        
        echo "Push in corso..."
        git push -u origin main
        echo ""
        echo -e "${GREEN}✓ Push completato!${NC}"
        ;;
        
    3)
        echo ""
        echo -e "${YELLOW}═══ Pubblica su Docker Hub ═══${NC}"
        echo ""
        echo -n "Username Docker Hub: "
        read docker_username
        echo -n "Nome immagine [db-backup-sidecar]: "
        read image_name
        image_name=${image_name:-db-backup-sidecar}
        echo -n "Tag [latest]: "
        read tag
        tag=${tag:-latest}
        
        full_name="${docker_username}/${image_name}:${tag}"
        
        echo ""
        echo "1. Login a Docker Hub..."
        docker login
        
        echo ""
        echo "2. Tagging immagine..."
        docker tag db-backup-sidecar:latest "$full_name"
        
        echo ""
        echo "3. Push immagine..."
        docker push "$full_name"
        
        echo ""
        echo -e "${GREEN}✓ Immagine pubblicata: $full_name${NC}"
        echo ""
        echo "Usa nei tuoi progetti:"
        echo "  image: $full_name"
        ;;
        
    4)
        echo ""
        echo -e "${YELLOW}═══ Pubblica su GitHub Container Registry ═══${NC}"
        echo ""
        echo -n "Username GitHub: "
        read github_username
        echo -n "Nome immagine [db-backup-sidecar]: "
        read image_name
        image_name=${image_name:-db-backup-sidecar}
        echo -n "Tag [latest]: "
        read tag
        tag=${tag:-latest}
        
        full_name="ghcr.io/${github_username}/${image_name}:${tag}"
        
        echo ""
        echo "Hai bisogno di un Personal Access Token con permessi 'write:packages'"
        echo "Crealo qui: https://github.com/settings/tokens"
        echo ""
        echo -n "Personal Access Token: "
        read -s token
        echo ""
        
        echo ""
        echo "1. Login a GitHub Container Registry..."
        echo "$token" | docker login ghcr.io -u "$github_username" --password-stdin
        
        echo ""
        echo "2. Tagging immagine..."
        docker tag db-backup-sidecar:latest "$full_name"
        
        echo ""
        echo "3. Push immagine..."
        docker push "$full_name"
        
        echo ""
        echo -e "${GREEN}✓ Immagine pubblicata: $full_name${NC}"
        echo ""
        echo "Usa nei tuoi progetti:"
        echo "  image: $full_name"
        ;;
        
    5)
        echo ""
        echo -e "${YELLOW}═══ Crea Tag Versione ═══${NC}"
        echo ""
        echo -n "Versione (es: v1.0.0): "
        read version
        echo -n "Descrizione (opzionale): "
        read description
        
        if [ -z "$description" ]; then
            git tag "$version"
        else
            git tag -a "$version" -m "$description"
        fi
        
        echo ""
        echo -e "${GREEN}✓ Tag $version creato${NC}"
        echo ""
        echo "Per pushare il tag:"
        echo "  git push origin $version"
        echo ""
        echo "O tutti i tag:"
        echo "  git push --tags"
        ;;
        
    6)
        echo ""
        echo -e "${YELLOW}═══ Informazioni Repository ═══${NC}"
        echo ""
        echo "Branch corrente:"
        git branch --show-current
        echo ""
        echo "Remote configurati:"
        git remote -v
        echo ""
        echo "Ultimi 5 commit:"
        git log --oneline -5
        echo ""
        echo "Tag:"
        git tag -l
        echo ""
        echo "File modificati:"
        git status --short
        ;;
        
    7)
        echo "Bye! 👋"
        exit 0
        ;;
        
    *)
        echo -e "${RED}Scelta non valida${NC}"
        exit 1
        ;;
esac

echo ""
