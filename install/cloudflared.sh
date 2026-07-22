#!/usr/bin/env bash
set -e

source /scripts/infra.conf
source /scripts/lib.sh

# Los CT o VM de Conexión tendrán rango ID 190-199
CTID=$CT_CLOUDFLARED
VARS_FILE="/usr/local/community-scripts/defaults/cloudflared.vars"

echo "Creando archivo vars..."

#           APP          HOSTNAME       IP                  CPU RAM DISK TUN GPU NEST
create_vars "Cloudflared" "cloudflared" "debian" "13" "$CLOUDFLARED_IP" 1 512 4 yes no 0

echo "Verificando que el LXC ID $CTID está Libre."
if pct status "$CTID" &>/dev/null; then
    echo "El CT $CTID ya existe."
    exit 1
fi

echo "Instalando Debian 13 limpio..."

create_lxc_from_vars "$CTID" "$VARS_FILE"

pct set "$CTID" --onboot 1

echo
echo "Configuración del contenedor:"
pct config "$CTID"

pct start "$CTID"

echo "Esperando inicio del contenedor..."

until pct exec "$CTID" -- hostname &>/dev/null; do
    sleep 2
done

echo
echo "Instalando Cloudflared..."

pct exec "$CTID" -- bash -c '

set -e

apt update
apt install -y curl ca-certificates gnupg

mkdir -p /usr/share/keyrings

curl -fsSL \
https://pkg.cloudflare.com/cloudflare-public-v2.gpg \
-o /usr/share/keyrings/cloudflare-public-v2.gpg

if [[ ! -s /usr/share/keyrings/cloudflare-public-v2.gpg ]]; then
    echo "ERROR: No se pudo descargar la llave GPG de Cloudflare"
    exit 1
fi

chmod 644 /usr/share/keyrings/cloudflare-public-v2.gpg


echo "deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main" \
> /etc/apt/sources.list.d/cloudflared.list


apt update
apt install -y cloudflared
'

pct exec "$CTID" -- cloudflared --version

echo
echo "================================================"
echo "Configuración del túnel Cloudflare"
echo "================================================"

echo
echo "Entre en:"
echo
echo "Cloudflare Zero Trust"
echo " -> Networks"
echo " -> Tunnels"
echo " -> Seleccionar túnel"
echo " -> Add a Connector"
echo " -> Debian 64-bit"
echo
echo "Copie el segundo text box mostrado por Cloudflare."
echo


read -rp "> " INPUT


TOKEN=$(awk '{print $NF}' <<< "$INPUT")


if [[ ${#TOKEN} -lt 60 ]]; then

    echo
    echo "ERROR: El token no parece válido."
    echo "Longitud detectada: ${#TOKEN}"
    exit 1

fi


echo
echo "Token válido detectado (${#TOKEN} caracteres)."


pct exec "$CTID" -- cloudflared service install "$TOKEN"

echo "Verificando servicio Cloudflared..."

pct exec "$CTID" -- systemctl enable cloudflared

pct exec "$CTID" -- systemctl restart cloudflared

pct exec "$CTID" -- systemctl is-active --quiet cloudflared || {
    echo "ERROR: Cloudflared no inició correctamente"
    pct exec "$CTID" -- journalctl -u cloudflared -n 50 --no-pager
    exit 1
}

echo
echo "=============================================="
echo " Cloudflared instalado correctamente"
echo " CTID: $CTID"
echo " IP: $CLOUDFLARED_IP"
echo "=============================================="
