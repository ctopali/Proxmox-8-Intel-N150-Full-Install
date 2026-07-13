#creamos el directorio de configuracion de los helper script si no existe
mkdir -p /usr/local/community-scripts/defaults

echo "--- 1. Incorporamos la infrastructura de redes: ---"
wget -O /scripts/infra.conf "https://raw.githubusercontent.com/ctopali/Proxmox-8-Intel-N150-Full-Install/refs/heads/main/infra.conf"
source /scripts/infra.conf

echo "--- 2. Copiamos los archvios .vars para la instalacion Helper-Scripts: ---"
wget -O /usr/local/community-script/defaults/adguard_test.vars "https://raw.githubusercontent.com/ctopali/Proxmox-8-Intel-N150-Full-Install/refs/heads/main/configs/adguard_test.vars"
cat /usr/local/community-script/defaults/adguard_test.vars
