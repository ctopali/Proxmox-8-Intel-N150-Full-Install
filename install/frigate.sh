#!/usr/bin/env bash
set -euo pipefail

source /scripts/infra.conf
source /scripts/lib.sh


echo "Creando archivo vars: ---"

create_vars "Frigate" "frigate" "debian" "12" "$FRIGATE_IP" 4 4096 32 yes yes 1

echo "A continuación se ejecutará la instalación Helper-Script de"
echo "Adguard Home, por favor, selecciona no compartir user data"
echo "y también selecciona en template 'App Defaults ...'."
echo
echo "Instalando Frigate Helper Script..."
echo

bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/frigate.sh)"


CTID=$(get_ctid_by_hostname frigate)


echo
echo "Configurando almacenamiento ZFS"
echo


pct stop "$CTID"

pct set "$CTID" -mp0 /mnt/frigate,mp=/media/frigate

pct start "$CTID"


echo
echo "Probando escritura en frigate_mirror"
echo


if pct exec "$CTID" -- touch /media/frigate/recordings/test; then

    echo "OK: Frigate puede escribir en frigate_mirror"

    pct exec "$CTID" -- rm /media/frigate/recordings/test

else

    echo "ERROR: Frigate no puede escribir en frigate_mirror"
    exit 1

fi


echo
echo "Configurando config.yml de Frigate"
echo


pct exec "$CTID" -- bash -c '

CONFIG=/opt/frigate/config/config.yml

if [ -f "$CONFIG" ]; then
    cp "$CONFIG" "$CONFIG.backup.$(date +%Y%m%d-%H%M)"
fi


cat > "$CONFIG" <<EOF

mqtt:
  enabled: false

ffmpeg:
  hwaccel_args: auto


detectors:
  detector01:
    type: openvino
    device: AUTO


detect:
  enabled: true


record:
  enabled: false


objects:
  track:
    - person
    - car
    - dog
    - cat


go2rtc:
  streams:

    exterior_main:
      - "rtsp://admin:123456@192.168.1.30:554/stream1"

    exterior_sub:
      - "rtsp://admin:123456@192.168.1.30:554/stream2"


    patio1_main:
      - "rtsp://admin:123456@192.168.1.31:554/stream1"

    patio1_sub:
      - "rtsp://admin:123456@192.168.1.31:554/stream2"


    patio2_main:
      - "rtsp://admin:123456@192.168.1.32:554/stream1"

    patio2_sub:
      - "rtsp://admin:123456@192.168.1.32:554/stream2"



cameras:

  exterior:
    enabled: true
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/exterior_sub
          roles:
            - detect


  patio1:
    enabled: true
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/patio1_sub
          roles:
            - detect


  patio2:
    enabled: true
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/patio2_sub
          roles:
            - detect



model:
  width: 300
  height: 300
  input_tensor: nhwc
  input_pixel_format: bgr
  path: /openvino-model/ssdlite_mobilenet_v2.xml
  labelmap_path: /openvino-model/coco_91cl_bkgr.txt


version: 0.17-0

EOF
'


echo
echo "Reiniciando Frigate..."
echo

pct exec "$CTID" -- systemctl restart frigate


echo
echo "======================================"
echo " Frigate instalado y configurado"
echo " CTID: $CTID"
echo " IP: $FRIGATE_IP"
echo " Media: /media/frigate"
echo "======================================"
