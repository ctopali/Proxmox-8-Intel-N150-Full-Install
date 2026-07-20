#!/usr/bin/env bash
set -e

echo "Creando archivo vars: ---"
#           APP       HOSTNAME  IP           CPU RAM DISK TUN GPU NEST
create_vars "AdGuard" "adguard" "debian" "13" "$ADGUARD_IP" 1 512 2 yes no 0
