#!/usr/bin/env bash
set -e

source /scripts/infra.conf
source /scripts/lib.sh

echo "Creando archivo vars: ---"
#           APP       HOSTNAME  IP           CPU RAM DISK TUN GPU NEST
create_vars "docker-frigate-models" "docker-frigate-models" "debian" "13" "$DOCKER_IP" 2 2048 20 yes no 0

echo "A continuación se ejecutará la instalación Helper-Script de"
echo "Docker, por favor, selecciona no compartir user data"
echo "y también selecciona en template 'App Defaults ...'."
echo
echo "Ejecutando Instalación de Docker: ---"
read -rp "Press Enter to continue..."
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/docker.sh)"
