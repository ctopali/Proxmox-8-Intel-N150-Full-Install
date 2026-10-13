#!/usr/bin/env bash
set -e

source /scripts/infra.conf
source /scripts/lib.sh

# ID del contenedor
CTID=150

echo "Creando archivo vars..."

# Sintaxis de la librería ctopali:
# create_vars "APP" "HOSTNAME" "OS" "VERSION" "IP" "CPU" "RAM" "DISK" "TUN" "GPU" "NEST"
create_vars "Streaming" "streaming" "debian" "13" "$STREAMING_IP" 2 4096 16 yes yes 0

echo "Verificando que el LXC ID $CTID está Libre."
if pct status "$CTID" &>/dev/null; then
    echo "El CT $CTID ya existe."
    exit 1
fi

# --- CONFIGURACIÓN DEL ZFS COMPARTIDO ---
# Asegura que exista la estructura de carpetas en el ZFS del host (ajusta 'datos' si tu ZFS se llama diferente)
ZFS_POOL="datos" # Cambia esto por el nombre de tu ZFS si es distinto (ej. tank, pool, etc.)
STREAMING_PATH="/$ZFS_POOL/Streaming"

echo "Configurando directorios en el ZFS Compartido ($STREAMING_PATH)..."
mkdir -p "$STREAMING_PATH/media/movies"
mkdir -p "$STREAMING_PATH/media/tvshows"
mkdir -p "$STREAMING_PATH/downloads/completed"
mkdir -p "$STREAMING_PATH/downloads/incomplete"

echo "Instalando Debian 13 limpio..."
create_lxc_from_vars "$CTID" "$VARS_FILE"

# --- AÑADIR PUNTO DE MONTAJE (BIND MOUNT) DESDE EL ZFS AL LXC ---
# Esto monta /datos/Streaming del host dentro del LXC en /mnt/storage
echo "Añadiendo ZFS Compartido al contenedor LXC..."
pct set "$CTID" -mp0 "$STREAMING_PATH,mp=/mnt/storage"

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

# 3. Crear directorios de configuración de las apps apuntando al almacenamiento montado (/mnt/storage)
mkdir -p /opt/media-server/{jellyfin,qbittorrent,radarr,sonarr,prowlarr}

# 4. Crear archivo Docker Compose usando las rutas del ZFS montado
cat <<EOF > /opt/media-server/docker-compose.yml
version: "3.8"

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
      - /mnt/storage/media:/data
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
      - /mnt/storage/downloads:/downloads
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
      - /mnt/storage/media:/data
      - /mnt/storage/downloads:/downloads
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
      - /mnt/storage/media:/data
      - /mnt/storage/downloads:/downloads
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

echo "¡Instalación completada con éxito y enlazado al ZFS Compartido!"
'
