#!/usr/bin/env bash
set -e

source /scripts/infra.conf
source /scripts/lib.sh

echo "Creando archivo vars: ---"
#           APP       HOSTNAME  IP           CPU RAM DISK TUN GPU NEST
create_vars "AdGuard" "adguard" "debian" "13" "$ADGUARD_IP" 1 512 2 yes no 0

echo "A continuación se ejecutará la instalación Helper-Script de"
echo "Adguard Home, por favor, selecciona no compartir user data"
echo "y también selecciona en template 'App Defaults ...'."
echo
echo "Ejecutando Instalación de Adguard Home: ---"
read -rp "Press Enter to continue..."
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/adguard.sh)"
