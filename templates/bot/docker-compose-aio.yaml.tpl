version: '3'

services:
  keeper:
    image: ${docker_image}
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./config.yaml:/app/config.yaml
  wallet-tracker:
    image: ${docker_image_wallet_tracker}
    build:
      context: wallet-tracker
    env_file: .env
    restart: unless-stopped

  prometheus:
    image: prom/prometheus
    container_name: prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--web.config.file=/etc/prometheus/web.yml'
    ports:
      - 9090:9090
    restart: unless-stopped
    volumes:
      - ./prometheus:/etc/prometheus
      - prom_data:/prometheus
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    expose:
      - 9100
  grafana:
    image: grafana/grafana
    container_name: grafana
    env_file: .env.monitoring
    ports:
      - 3000:3000
    restart: unless-stopped
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards

volumes:
  prom_data:
