#!/usr/bin/env bash
set -e

source /scripts/infra.conf
source /scripts/lib.sh

echo "Creando archivo vars: ---"
#           APP       HOSTNAME  IP           CPU RAM DISK TUN GPU NEST
create_vars "AdGuard" "adguard" "debian" "13" "$ADGUARD_IP" 1 512 2 yes no 0

# Ejecutamos el Helper-Script:
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/adguard.sh)"
