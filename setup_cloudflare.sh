echo "--- 2.1 Creando los archivos de configuracion.vars ---"
#           APP       HOSTNAME  IP           CPU RAM DISK TUN GPU NEST
#create_vars "AdGuard" "adguard" "debian" "13" "$ADGUARD_IP" 1 512 2 yes no 0
#create_vars "Frigate" "frigate" "debian" "13" "$FRIGATE_IP" 4 4096 32 yes yes 1
#create_vars "Cloudflared" "cloudflared" "debian" "13" "$CLOUDFLARED_IP" 1 512 4 yes no 0

echo "--- 2.2. AdGuard ---"

echo "--- 2.3. Frigate ---"

echo "--- 2.4. Cloudflared ---"
# Instalacion de Debian 13 limpia:

    #Cambiar el LXC number cuando corresponda
    pct create 120 \
        "local:vztmpl/$(basename "$TEMPLATE")" \
        --hostname "$var_hostname" \
        --cores "$var_cpu" \
        --memory "$var_ram" \
        --rootfs ${var_container_storage}:${var_disk} \
        --net0 name=eth0,bridge=${var_brg},ip=${var_net},gw=${var_gateway} \
        --unprivileged "$var_unprivileged" \
        --features nesting=${var_nesting},keyctl=${var_keyctl}
}

pct set 120 --onboot 1
echo "A continuación debe aparecer: onboot: 1"
pct config 120
pct start 120

pct exec 120 -- bash -c '
# Add cloudflare gpg key
mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg \
 | tee /usr/share/keyrings/cloudflare-public-v2.gpg >/dev/null

# Add this repo to your apt repositories
echo "deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main" \
 > /etc/apt/sources.list.d/cloudflared.list

# install cloudflared
apt update
apt install -y cloudflared
'

# Leemos el input del usuario
echo
echo "Copiar el token del tunel entrando en Cloudflare.com -> Login -> Zero Trust -> Networks -> Tunnels & Mesh "\
"-> Seleccionar el tunel -> Add a Connector -> Select OS Debian & 64-bit -> Copy 2 text box"
echo "Pega el comando copiado desde Cloudflare Zero Trust:"
read -rp "> " INPUT

# Extraer el último argumento (el token)
TOKEN=$(awk '{print $NF}' <<< "$INPUT")

# Validar longitud mínima
if [[ ${#TOKEN} -lt 80 ]]; then
    echo
    echo "ERROR: No parece ser un token válido."
    echo "Token detectado: $TOKEN"
    echo "Longitud: ${#TOKEN} caracteres."
    exit 1
fi

echo "Token válido detectado (${#TOKEN} caracteres)."

pct exec 120 -- cloudflared service install "$TOKEN"
