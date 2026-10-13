#!/usr/bin/env bash

source /scripts/infra.conf
SUBNET="192.168.1"

echo "=================================================================================================="
echo "       AUDITORÍA DE SERVICIOS EN PROXMOX (Rango: $SUBNET.0 - $SUBNET.40)                          "
echo "=================================================================================================="
printf "%-16s | %-15s | %-8s | %-8s | %s\n" "SERVICIO" "IP" "PUERTO" "ESTADO" "DESCRIPCIÓN"
echo "--------------------------------------------------------------------------------------------------"

SERVICES=(
    "AdGuard DNS:53:Servidor DNS y Bloqueo de publicidad"
    "AdGuard Web:81:Panel de administración AdGuard"
    "Cloudflared:0:Túnel seguro Cloudflare (Sin puerto local)"
    "Frigate UI:8971:Interfaz web de Frigate NVR"
    "Frigate API:5000:API interna de Frigate"
    "Home Assistant:8123:Plataforma domótica principal"
    "Jellyfin:8096:Servidor de streaming multimedia"
    "qBittorrent:8080:Cliente de descargas P2P"
    "Radarr:7878:Gestor de películas automatizado"
    "Sonarr:8989:Gestor de series automatizado"
    "Prowlarr:9696:Indexador de trackers para *arr"
)

for i in $(seq 0 40); do
    ip="$SUBNET.$i"
    
    if ping -c 1 -W 1 "$ip" &>/dev/null; then
        for svc in "${SERVICES[@]}"
            name="${svc%%:*}"
            rest="${svc#*:}"
            port="${rest%%:*}"
            desc="${rest#*:}"

            if [ "$port" -eq 0 ]; then
                # Cloudflared se maneja aparte al final
                continue
            else
                if nc -z -w 1 "$ip" "$port" &>/dev/null; then
                    status="UP"
                else
                    status="DOWN"
                fi
                printf "%-16s | %-15s | %-8s | %-8s | %s\n" "$name" "$ip" "$port" "$status" "$desc"
            fi
        done
    fi
done

# Comprobación directa para Cloudflared
if pct status "$CT_CLOUDFLARED" 2>/dev/null | grep -q "running"; then
    cf_ip=$(pct exec "$CT_CLOUDFLARED" -- hostname -I 2>/dev/null | awk '{print $1}')
    printf "%-16s | %-15s | %-8s | %-8s | %s\n" "Cloudflared" "${cf_ip:-N/A}" "N/A" "UP" "Túnel seguro Cloudflare (Sin puerto local)"
else
    printf "%-16s | %-15s | %-8s | %-8s | %s\n" "Cloudflared" "N/A" "N/A" "DOWN" "Túnel seguro Cloudflare (Sin puerto local)"
fi
echo "=================================================================================================="
