#!/usr/bin/env bash
set -e

source /scripts/infra.conf
source /scripts/lib.sh

echo "Creando archivo vars: ---"
#           APP       HOSTNAME  IP           CPU RAM DISK TUN GPU NEST
echo "Creación del archivo frigate.vars..."
create_vars "Frigate" "frigate" "debian" "12" "$FRIGATE_IP" 4 4096 32 yes yes 1

echo "A continuación se ejecutará la instalación Helper-Script de"
echo "Frigate, por favor, selecciona no compartir user data"
echo "y también selecciona en template 'App Defaults ...'."
echo
echo "Instalación del servicio Frigate:"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/frigate.sh)"

CTID=get_ctid_by_hostname frigate

pct stop $CTID
pct set $CTID -mp0 /mnt/frigate,mp=/media/frigate
pct start $CTID
pct exec $CTID ls -lah /media/frigate

if ! touch /media/frigate/recordings/prueba then
  
# Modificación del archivo yaml de configuración de Frigate:
cat pct $CTID config.yaml < EOF
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
      - "rtsp://admin:123456@192.168.1.30:554/stream1" # High quality
    exterior_sub:
      - "rtsp://admin:123456@192.168.1.30:554/stream2" # Low quality
    patio1_main:
      - "rtsp://admin:123456@192.168.1.31:554/stream1" # High quality
    patio1_sub:
      - "rtsp://admin:123456@192.168.1.31:554/stream2" # Low quality
    patio2_main:
      - "rtsp://admin:123456@192.168.1.32:554/stream1" # High quality
    patio2_sub:
      - "rtsp://admin:123456@192.168.1.32:554/stream2" # Low quality
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
