#!/usr/bin/env bash
set -e

source /scripts/infra.conf
source /scripts/lib.sh

# ID del contenedor y VARS FILE (config del CT o VM)
CTID=$CT_STREAMING
VARS_FILE="/usr/local/community-scripts/defaults/streaming.vars"

echo "Creando archivo vars..."

# Sintaxis de la librería ctopali:
#           APP       HOSTNAME                    IP         CPU RAM DISK TUN GPU NEST UNPRIV
create_vars "Streaming" "streaming" "debian" "13" "$STREAMING_IP" 2 4096 16 yes yes 1 0

echo "Verificando que el LXC ID $CTID está Libre."
if pct status "$CTID" &>/dev/null; then
    echo "El CT $CTID ya existe."
    exit 1
fi

# --- CONFIGURACIÓN DEL ZFS COMPARTIDO ---
POOL="datos"

# 1. Verificar si existe /datos, /mnt/datos o si se puede configurar vía ZFS
if [ -d "/datos" ]; then
    ZFS_MOUNT="/datos"
    echo "Se encontró el directorio existente en $ZFS_MOUNT"
elif [ -d "/mnt/datos" ]; then
    ZFS_MOUNT="/mnt/datos"
    echo "Se encontró el directorio existente en $ZFS_MOUNT"
elif zfs list "$POOL" &>/dev/null; then
    ZFS_MOUNT="/mnt/datos"
    echo "Configurando el mountpoint para el pool ZFS $POOL en $ZFS_MOUNT..."
    zfs set mountpoint="${ZFS_MOUNT}" "${POOL}"
else
    echo "Error: No se encuentra la carpeta '/datos', '/mnt/datos' ni el pool ZFS '$POOL'."
    exit 1
fi

STREAMING_PATH="$ZFS_MOUNT/streaming"

echo "Configurando directorios en el ZFS Compartido ($STREAMING_PATH)..."
mkdir -p "$STREAMING_PATH/media/movies"
mkdir -p "$STREAMING_PATH/media/series"
mkdir -p "$STREAMING_PATH/downloads/completed"
mkdir -p "$STREAMING_PATH/downloads/incomplete"

echo "Aplicando permisos específicos a streaming..."
chown -R 0:0 "$STREAMING_PATH"
chmod -R 775 "$STREAMING_PATH"

echo "Instalando Debian 13 limpio..."
create_lxc_from_vars "$CTID" "$VARS_FILE"

# --- AÑADIR PUNTO DE MONTAJE (BIND MOUNT) DESDE EL ZFS AL LXC ---
echo "Añadiendo ZFS Compartido al contenedor LXC..."

if pct config "$CTID" | grep -q "^mp0:"; then
    pct set "$CTID" -delete mp0
fi

pct set "$CTID" -mp0 "$STREAMING_PATH,mp=/mnt/streaming"
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
echo "Instalando Jellyfin, qBittorrent, Radarr, Sonarr, Prowlarr..."

pct exec "$CTID" -- bash -c '
set -e

# 1. Actualizar el sistema e instalar prerrequisitos
export DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -y
apt install -y curl apt-transport-https ca-certificates gnupg lsb-release git

# 2. Instalar Docker y Docker Compose
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 3. Crear directorios de configuración de las apps
mkdir -p /opt/media-server/{jellyfin,qbittorrent,radarr,sonarr,prowlarr}

# 4. Crear archivo Docker Compose usando las rutas actualizadas hacia /mnt/streaming
cat <<EOF > /opt/media-server/docker-compose.yml
services:
  jellyfin:
    image: linuxserver/jellyfin
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Santiago
    devices:
      - /dev/dri/renderD128:/dev/dri/renderD128
    volumes:
      - ./jellyfin:/config
      - /mnt/streaming/media:/data
    ports:
      - 8096:8096
    restart: unless-stopped

  qbittorrent:
    image: linuxserver/qbittorrent
    container_name: qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Santiago
      - WEBUI_PORT=8080
    volumes:
      - ./qbittorrent:/config
      - /mnt/streaming/downloads:/downloads
    ports:
      - 8080:8080
      - 6881:6881
      - 6881:6881/udp
    restart: unless-stopped

  radarr:
    image: linuxserver/radarr
    container_name: radarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Santiago
    volumes:
      - ./radarr:/config
      - /mnt/streaming/media:/data
      - /mnt/streaming/downloads:/downloads
    ports:
      - 7878:7878
    restart: unless-stopped

  sonarr:
    image: linuxserver/sonarr
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Santiago
    volumes:
      - ./sonarr:/config
      - /mnt/streaming/media:/data
      - /mnt/streaming/downloads:/downloads
    ports:
      - 8989:8989
    restart: unless-stopped

  prowlarr:
    image: linuxserver/prowlarr
    container_name: prowlarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Santiago
    volumes:
      - ./prowlarr:/config
    ports:
      - 9696:9696
    restart: unless-stopped
EOF

# 5. Levantar los servicios
cd /opt/media-server
docker compose up -d
'

echo "¡Instalación completada con éxito y enlazado al ZFS Compartido en /mnt/streaming!"
